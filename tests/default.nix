{ pkgs ? import <nixpkgs> {} }:

let

  nmt = pkgs.fetchFromGitLab {
    owner = "rycee";
    repo = "nmt";
    rev = "89fb12a2aaa8ec671e22a033162c7738be714305";
    sha256 = "07yc1jkgw8vhskzk937k9hfba401q8rn4sgj9baw3fkjl9zrbcyf";
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
    git-with-email = ./modules/programs/git-with-email.nix;
    git-with-most-options = ./modules/programs/git.nix;
    git-with-str-extra-config = ./modules/programs/git-with-str-extra-config.nix;
    mbsync = ./modules/programs/mbsync.nix;
    texlive-minimal = ./modules/programs/texlive-minimal.nix;
    xresources = ./modules/xresources.nix;
  }
  // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux (
    {
      i3-keybindings = ./modules/services/window-managers/i3-keybindings.nix;
    }
    // import ./modules/misc/pam
    // import ./modules/systemd
  )
  // import ./modules/home-environment
  // import ./modules/misc/fontconfig
  // import ./modules/programs/alacritty
  // import ./modules/programs/bash
  // import ./modules/programs/ssh
  // import ./modules/programs/tmux
  // import ./modules/programs/zsh;
}
