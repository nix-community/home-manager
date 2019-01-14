{ pkgs ? import <nixpkgs> {} }:

let

  nmt = pkgs.fetchFromGitLab {
    owner = "rycee";
    repo = "nmt";
    rev = "2ed3897e22ee0e1d343ba2c33122d57d888dedfe";
    sha256 = "1k4qapinsvrf40ccpva6rfp11b90h413xrf5h57v84m88fcgac7n";
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
  } // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
    "i3/keybindings" = ./modules/services/window-managers/i3-keybindings.nix;
  };
}
