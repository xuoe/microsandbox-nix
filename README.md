# microsandbox-nix

Nix packaging for [microsandbox](https://microsandbox.dev)
([repo](https://github.com/superradcompany/microsandbox)).
It installs the prebuilt `msb` CLI and its matching `libkrunfw` from the official
release.

## Requirements

| System           | Requirement                                   |
| ---------------- | --------------------------------------------- |
| `x86_64-linux`   | `/dev/kvm` access                             |
| `aarch64-linux`  | `/dev/kvm` access                             |
| `aarch64-darwin` | Apple silicon                                 |

On NixOS, add your user to the `kvm` group:

```nix
# configuration.nix
users.users.YOUR_USER.extraGroups = [ "kvm" ];
```

## Try

```bash
# Run msb once (flakes).
$ nix run github:xuoe/microsandbox-nix -- --version
msb 0.7.11

# Open a shell with msb on PATH (flakes).
$ nix shell github:xuoe/microsandbox-nix
$ msb --version
msb 0.7.11

# Build msb without flakes.
$ nix-build https://github.com/xuoe/microsandbox-nix/archive/master.tar.gz
$ ./result/bin/msb --version
msb 0.7.11
```

## Install

### System (flake)

```nix
# flake.nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.microsandbox.url = "github:xuoe/microsandbox-nix";

  outputs = { nixpkgs, microsandbox, ... }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ({ ... }: {
            environment.systemPackages = [
              microsandbox.packages.${system}.default
            ];
          })
          # You can also use the overlay instead:
          # ({ pkgs, ... }: {
          #    nixpkgs.overlays = [ microsandbox.overlays.default ];
          #    environment.systemPackages = [ pkgs.microsandbox ];
          # })
        ];
      };
    };
}
```

### System (classic)

```nix
let
  src = builtins.fetchTarball {
    url = "https://github.com/xuoe/microsandbox-nix/archive/REVISION.tar.gz";
    sha256 = "..."; # nix-prefetch-url --unpack <url>
  };
in
{ pkgs, ... }:
{
  nixpkgs.overlays = [ (import "${src}/overlay.nix") ];
  environment.systemPackages = [ pkgs.microsandbox ];
}
```

## Updates

GitHub Actions checks upstream every six hours and commits an update if a new
release appears. To pick it up in your config:

```bash
$ nix flake update microsandbox
```
