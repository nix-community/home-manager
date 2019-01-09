{ pkgs ? import <nixpkgs> {} }:

let

  nmt = pkgs.fetchFromGitLab {
    owner = "rycee";
    repo = "nmt";
    rev = "4d7b4bb34ed9df333b5aa54509e50881f3a59939";
    sha256 = "1rha4n5xafxwa5gbrjwnm63z944jr27gv71krkzzmb5wapi1r36m";
  };

in

import nmt {
  inherit pkgs;
  modules = import ../modules/modules.nix { inherit pkgs; lib = pkgs.lib; };
  testedAttrPath = [ "home" "activationPackage" ];
  tests = {
    "git/with-most-options" = ./modules/programs/git.nix;
    "git/with-str-extra-config" = ./modules/programs/git-with-str-extra-config.nix;
    texlive-minimal = ./modules/programs/texlive-minimal.nix;
    xresources = ./modules/xresources.nix;
  };
}
