# microsandbox-nix

A Nix flake for [microsandbox](https://microsandbox.dev)
([superradcompany/microsandbox](https://github.com/superradcompany/microsandbox)): it installs the prebuilt `msb` CLI and its matching `libkrunfw` from the
official release.

The binaries are bundled, so using this flake avoids compiling the guest kernel
and the Rust crates.

## Supported Systems

- `x86_64-linux`
- `aarch64-linux`
- `aarch64-darwin` (Apple silicon)

## Requirements

- **Linux:** access to `/dev/kvm`, and your user in the `kvm` group
- **macOS:** an Apple silicon machine

On NixOS:

```nix
users.users.YOUR_USER.extraGroups = [ "kvm" ];
```

## Usage

To try `msb` without installing it:

```bash
$ nix run github:xuoe/microsandbox-nix -- --help
# or
$ nix shell github:xuoe/microsandbox-nix
$ msb --version
msb 0.7.8
```

To install it, choose one of the following methods.

### Nix profile

Install the package into your user profile with:

```bash
$ nix profile install github:xuoe/microsandbox-nix
```

### Home Manager

Add the flake to your inputs:

```nix
inputs.microsandbox.url = "github:xuoe/microsandbox-nix";
```

Pass the package to Home Manager with `extraSpecialArgs`:

```nix
{
  outputs = { nixpkgs, home-manager, microsandbox, ... }:
    let
      system = "x86_64-linux"; # your system
    in {
    homeConfigurations.<USER> = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${system};
      extraSpecialArgs = {
        msb = microsandbox.packages.${system}.msb;
      };
      modules = [ ./home.nix ];
    };
  };
}
```

Then add it in `home.nix`:

```nix
{ msb, ... }:
{
  home.packages = [ msb ];
}
```

### NixOS

Add the flake to your inputs:

```nix
inputs.microsandbox.url = "github:xuoe/microsandbox-nix";
```

Pass the package to NixOS with `specialArgs`:

```nix
{
  outputs = { nixpkgs, microsandbox, ... }:
    let
      system = "x86_64-linux"; # your system
    in {
    nixosConfigurations.<HOST> = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        msb = microsandbox.packages.${system}.msb;
      };
      modules = [ ./configuration.nix ];
    };
  };
}
```

Then add it in `configuration.nix`:

```nix
{ msb, ... }:
{
  environment.systemPackages = [ msb ];
}
```

## Updates

The packaged version is refreshed from upstream automatically through GitHub Actions. When using this flake as an input, your `flake.lock` pins the version; update it with:

```bash
$ nix flake update microsandbox
```
