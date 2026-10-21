{
  pkgs ? import <nixpkgs> { },
}:
pkgs.mkShell {
  packages = [
    (pkgs.callPackage ./package.nix { })
    pkgs.bash
    pkgs.coreutils
    pkgs.curl
    pkgs.jq
    pkgs.perl
    pkgs.nixfmt-tree
  ];
}
