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
          formatting =
            pkgs.runCommand "formatting-check"
              {
                nativeBuildInputs = [ pkgs.nixfmt-tree ];
              }
              ''
                cp -r --no-preserve=mode ${self} src
                cd src
                treefmt --fail-on-change --no-cache --tree-root . --walk filesystem
                touch $out
              '';
        }
      );
    };
}
