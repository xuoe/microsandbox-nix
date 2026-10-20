{
  description = "Prebuilt microsandbox (msb + libkrunfw)";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      sources = import ./sources.nix;
      systems = builtins.attrNames (builtins.removeAttrs sources [ "version" ]);

      mkPackage =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          arch = lib.head (lib.splitString "-" system);
          os = lib.last (lib.splitString "-" system);

          msb = pkgs.stdenv.mkDerivation {
            pname = "msb";
            version = sources.version;

            src = pkgs.fetchurl {
              url = "https://github.com/superradcompany/microsandbox/releases/download/v${sources.version}/microsandbox-${os}-${arch}.tar.gz";
              sha256 = sources.${system};
            };

            # The bundle has no top-level directory.
            sourceRoot = ".";

            # The vendor binaries are already stripped.
            dontStrip = true;

            nativeBuildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
              pkgs.autoPatchelfHook
            ];

            # libstdc++ and libgcc_s are needed on Linux.
            buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
              pkgs.stdenv.cc.cc.lib
            ];

            installPhase = ''
              runHook preInstall
              install -Dm755 msb $out/bin/msb
              install -Dm755 -t $out/lib libkrunfw.*
              runHook postInstall
            '';

            meta = {
              description = "Easy, fast, programmable and local-first microVM runtime";
              homepage = "https://microsandbox.dev";
              license = with lib.licenses; [
                asl20 # msb
                gpl2Only # linux kernel + patches
                lgpl21Only # libkrunfw
              ];
              mainProgram = "msb";
              platforms = [ pkgs.stdenv.hostPlatform.system ];
              sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
            };
          };
        in
        {
          inherit msb;
          default = msb;
        };
    in
    rec {
      forAllSystems = lib.genAttrs systems;
      packages = forAllSystems mkPackage;
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
      checks = forAllSystems (system: {
        inherit (self.packages.${system}) msb;
      });
    };
}
