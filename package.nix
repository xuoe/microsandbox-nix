{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:
let
  inherit (stdenv.hostPlatform) system;
  version = lib.trim (builtins.readFile ./version);
  checksums = builtins.fromJSON (builtins.readFile ./checksums.json);
  supportedSystem = checksums ? ${system};
  systems = builtins.attrNames checksums;
  arch = lib.head (lib.splitString "-" system);
  os = lib.last (lib.splitString "-" system);
in
assert supportedSystem || throw "microsandbox ${version} has no release asset for ${system}";
stdenv.mkDerivation {
  pname = "microsandbox";
  inherit version;

  src = fetchurl {
    url = "https://github.com/superradcompany/microsandbox/releases/download/v${version}/microsandbox-${os}-${arch}.tar.gz";
    sha256 = checksums.${system};
  };

  # The bundle has no top-level directory.
  sourceRoot = ".";

  # The vendor binaries are already stripped.
  dontStrip = true;

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    autoPatchelfHook
  ];

  # libstdc++ and libgcc_s are needed on Linux.
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 msb $out/bin/msb
    install -Dm755 -t $out/lib libkrunfw.*
    runHook postInstall
  '';

  meta = {
    platforms = systems;
    description = "Easy, fast, programmable and local-first microVM runtime";
    homepage = "https://microsandbox.dev";
    license = with lib.licenses; [
      asl20 # msb
      gpl2Only # linux kernel + patches
      lgpl21Only # libkrunfw
    ];
    mainProgram = "msb";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
