{ pkgs ? import <nixpkgs> { }, ... }:

pkgs.stdenv.mkDerivation {
  name = "giggio-cheats";
  src = ./.;
  nativeBuildInputs = [ pkgs.util-linux ];
  buildPhase = "bash ./build.sh";
  installPhase = ''
    mkdir -p "$out/share/navi/cheats/"
    cp -R ./dist/* "$out/share/navi/cheats/"
  '';
}
