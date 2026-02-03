{
  description = "Giovanni's cheat cheats";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        formatter = pkgs.nixpkgs-fmt;
        packages = {
          default = (pkgs.callPackage ./default.nix { });
        };
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            (bats.withLibraries (p: [
              p.bats-support
              p.bats-assert
            ]))
            gawk
          ];
          shellHook = ''
            export BATS_LIB_PATH=${pkgs.bats}/share/bats/
          '';
        };
      }
    );
}
