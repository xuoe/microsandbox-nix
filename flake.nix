{
  description = "Prebuilt microsandbox (msb + libkrunfw)";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      checksums = builtins.fromJSON (builtins.readFile ./checksums.json);
      systems = builtins.attrNames checksums;
      overlay = import ./overlay.nix;
      forAllSystems = lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system}.extend overlay;
        in
        {
          msb = pkgs.microsandbox;
          default = pkgs.microsandbox;
        }
      );
      overlays.default = overlay;
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          inherit (self.packages.${system}) msb;
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
