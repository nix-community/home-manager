{ pkgs ? import <nixpkgs> {} }:

let

  lib = import ../modules/lib/stdlib-extended.nix pkgs.lib;

  nmt = pkgs.fetchFromGitLab {
    owner = "rycee";
    repo = "nmt";
    rev = "4174e11107ba808b3001ede2f9f245481dfdfb2e";
    sha256 = "0vzdh7211dxmd4c3371l5b2v5i3b8rip2axk8l5xqlwddp3jiy5n";
  };

  modules = import ../modules/modules.nix {
    inherit lib pkgs;
    check = false;
  };

in

import nmt {
  inherit lib pkgs modules;
  testedAttrPath = [ "home" "activationPackage" ];
  tests = builtins.foldl' (a: b: a // (import b)) { } ([
    ./lib/types
    ./modules/files
    ./modules/home-environment
    ./modules/misc/fontconfig
    ./modules/programs/alacritty
    ./modules/programs/bash
    ./modules/programs/browserpass
    ./modules/programs/fish
    ./modules/programs/git
    ./modules/programs/gpg
    ./modules/programs/lieer
    ./modules/programs/mbsync
    ./modules/programs/neomutt
    ./modules/programs/newsboat
    ./modules/programs/readline
    ./modules/programs/ssh
    ./modules/programs/starship
    ./modules/programs/texlive
    ./modules/programs/tmux
    ./modules/programs/zsh
    ./modules/xresources
  ] ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
    ./modules/misc/debug
    ./modules/misc/pam
    ./modules/misc/xdg
    ./modules/misc/xsession
    ./modules/programs/abook
    ./modules/programs/firefox
    ./modules/programs/getmail
    ./modules/programs/rofi
    ./modules/services/polybar
    ./modules/services/sxhkd
    ./modules/services/window-managers/i3
    ./modules/systemd
  ]);
}
