# microsandbox-nix

Nix packaging for [microsandbox](https://microsandbox.dev)
([superradcompany/microsandbox](https://github.com/superradcompany/microsandbox)).
It installs the prebuilt `msb` CLI and its matching `libkrunfw` from the official
release, so nothing is compiled from source.

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

## Quick Usage

```bash
# Run msb once (flakes).
$ nix run github:xuoe/microsandbox-nix -- --version
msb 0.7.8

# Open a shell with msb on PATH (flakes).
$ nix shell github:xuoe/microsandbox-nix
$ msb --version
msb 0.7.8

# Build msb without flakes.
$ nix-build https://github.com/xuoe/microsandbox-nix/archive/master.tar.gz
$ ./result/bin/msb --version
msb 0.7.8
```

## Installation

### NixOS flake (overlay)

```nix
# flake.nix
{
  inputs.microsandbox.url = "github:xuoe/microsandbox-nix";

  outputs = { nixpkgs, microsandbox, ... }: {
    nixosConfigurations.YOUR_HOST = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        { nixpkgs.overlays = [ microsandbox.overlays.default ]; }
        ./configuration.nix
      ];
    };
  };
}

# configuration.nix
{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.microsandbox ];
}
```

### NixOS flake (module argument)

```nix
# flake.nix
{
  inputs.microsandbox.url = "github:xuoe/microsandbox-nix";

  outputs = { nixpkgs, microsandbox, ... }: {
    nixosConfigurations.YOUR_HOST = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        microsandbox = microsandbox.packages.x86_64-linux.msb;
      };
      modules = [ ./configuration.nix ];
    };
  };
}

# configuration.nix
{ microsandbox, ... }:
{
  environment.systemPackages = [ microsandbox ];
}
```

### Home Manager flake (overlay)

```nix
# flake.nix
{
  inputs.microsandbox.url = "github:xuoe/microsandbox-nix";

  outputs = { nixpkgs, home-manager, microsandbox, ... }:
    let
      system = "x86_64-linux";
    in {
      homeConfigurations.YOUR_USER = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ microsandbox.overlays.default ];
        };
        modules = [ ./home.nix ];
      };
    };
}

# home.nix
{ pkgs, ... }:
{
  home.packages = [ pkgs.microsandbox ];
}
```

### Home Manager flake (module argument)

```nix
# flake.nix
{
  inputs.microsandbox.url = "github:xuoe/microsandbox-nix";

  outputs = { nixpkgs, home-manager, microsandbox, ... }:
    let
      system = "x86_64-linux";
    in {
      homeConfigurations.YOUR_USER = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = {
          microsandbox = microsandbox.packages.${system}.msb;
        };
        modules = [ ./home.nix ];
      };
    };
}

# home.nix
{ microsandbox, ... }:
{
  home.packages = [ microsandbox ];
}
```

### Classic NixOS (overlay)

To use the overlay in a classic NixOS configuration, pin this repository:

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

### Classic Nix (checkout)

From a checkout of this repository:

```bash
# Build msb to ./result/bin/msb
$ nix-build

# Install msb into your profile
$ nix-env -f . -i

# Spawn a shell with msb on PATH
$ nix-shell
```

## Updates

GitHub Actions checks upstream every six hours and commits an update if a new
release appears. To pick it up in your config:

```bash
$ nix flake update microsandbox
```
