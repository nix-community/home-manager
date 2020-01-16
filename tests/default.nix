{ pkgs ? import <nixpkgs> {} }:

let

  lib = import ../modules/lib/stdlib-extended.nix pkgs.lib;

  nmt = pkgs.fetchFromGitLab {
    owner = "rycee";
    repo = "nmt";
    rev = "6f866d1acb89fa15cd3b62baa052deae1f685c0c";
    sha256 = "1qr1shhapjn4nnd4k6hml69ri8vgz4l8lakjll5hc516shs9a9nn";
  };

  modules = import ../modules/modules.nix { inherit lib pkgs; check = false; };

in

import nmt {
  inherit lib pkgs modules;
  testedAttrPath = [ "home" "activationPackage" ];
  tests = {
    browserpass = ./modules/programs/browserpass.nix;
    mbsync = ./modules/programs/mbsync.nix;
    texlive-minimal = ./modules/programs/texlive-minimal.nix;
    xresources = ./modules/xresources.nix;
  }
  // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux (
    {
      getmail = ./modules/programs/getmail.nix;
      i3-keybindings = ./modules/services/window-managers/i3-keybindings.nix;
    }
    // import ./modules/misc/pam
    // import ./modules/misc/xdg
    // import ./modules/misc/xsession
    // import ./modules/programs/firefox
    // import ./modules/programs/rofi
    // import ./modules/services/sxhkd
    // import ./modules/systemd
  )
  // import ./lib/types
  // import ./modules/files
  // import ./modules/home-environment
  // import ./modules/misc/fontconfig
  // import ./modules/programs/alacritty
  // import ./modules/programs/bash
  // import ./modules/programs/git
  // import ./modules/programs/gpg
  // import ./modules/programs/newsboat
  // import ./modules/programs/readline
  // import ./modules/programs/ssh
  // import ./modules/programs/tmux
  // import ./modules/programs/zsh;
}
