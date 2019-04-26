{ pkgs ? import <nixpkgs> {} }:

let

  nmt = pkgs.fetchFromGitLab {
    owner = "rycee";
    repo = "nmt";
    rev = "b6ab61e707ec1ca3839fef42f9960a1179d543c4";
    sha256 = "097fm1hmsyhy8chf73wwrvafcxny37414fna3haxf0q5fvpv4jfb";
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
  // import ./modules/programs/bash
  // import ./modules/programs/ssh
  // import ./modules/programs/tmux
  // import ./modules/programs/zsh;
}
