{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = [ (pkgs.python311.withPackages (ps: with ps; [ black ])) ];
}
