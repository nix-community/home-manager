{ pkgs, mkShell }:
let
  formatter = pkgs.callPackage ./formatter.nix { };
in
mkShell {
  name = "devShell";
  packages = [
    pkgs.coreutils
    formatter
  ];
}
