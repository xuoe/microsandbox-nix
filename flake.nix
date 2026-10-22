{
  description = "Prebuilt microsandbox (msb + libkrunfw)";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      checksums = builtins.fromJSON (builtins.readFile ./checksums.json);
      systems = builtins.attrNames checksums;
      eachSystem = lib.genAttrs systems;
      pkgsFor = system: nixpkgs.legacyPackages.${system};
      overlay = import ./overlay.nix;
    in
    {
      packages = eachSystem (system: {
        default = import ./default.nix { pkgs = pkgsFor system; };
      });
      overlays.default = overlay;
      formatter = eachSystem (system: (pkgsFor system).nixfmt-tree);
      checks = eachSystem (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          inherit (self.packages.${system}) default;
          formatting = pkgs.runCommand "formatting-check" { nativeBuildInputs = [ pkgs.nixfmt ]; } ''
            nixfmt --check ${self}/*.nix
            touch $out
          '';

          shellcheck = pkgs.runCommand "shellcheck-check" { nativeBuildInputs = [ pkgs.shellcheck ]; } ''
            shellcheck ${self}/.github/scripts/*
            touch $out
          '';

          actionlint = pkgs.runCommand "actionlint-check" { nativeBuildInputs = [ pkgs.actionlint ]; } ''
            actionlint ${self}/.github/workflows/*.yml
            touch $out
          '';
        }
      );
    };
}
