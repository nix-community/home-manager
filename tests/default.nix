{ pkgs ? import <nixpkgs> {} }:

let

  nmt = pkgs.fetchFromGitLab {
    owner = "rycee";
    repo = "nmt";
    rev = "02a01605021df3d8d43346076bd065109b10e4f9";
    sha256 = "1b5f534xskp4qdnh0nmflqm6v1a014a883x3abscf4xd0pxb8cj7";
  };

in

import nmt {
  inherit pkgs;
  modules = import ../modules/modules.nix { inherit pkgs; lib = pkgs.lib; };
  testedAttrPath = [ "home" "activationPackage" ];
  tests = {
    files-executable = ./modules/files/executable.nix;
    files-hidden-source = ./modules/files/hidden-source.nix;
    files-source-with-spaces = ./modules/files/source-with-spaces.nix;
    files-text = ./modules/files/text.nix;
    git-with-most-options = ./modules/programs/git.nix;
    git-with-str-extra-config = ./modules/programs/git-with-str-extra-config.nix;
    texlive-minimal = ./modules/programs/texlive-minimal.nix;
    xresources = ./modules/xresources.nix;
  } // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
    i3-keybindings = ./modules/services/window-managers/i3-keybindings.nix;
  };
}
