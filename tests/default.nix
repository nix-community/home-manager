{ pkgs ? import <nixpkgs> {} }:

let

  lib = import ../modules/lib/stdlib-extended.nix pkgs.lib;

  nmt = pkgs.fetchFromGitLab {
    owner = "rycee";
    repo = "nmt";
    rev = "ae9ce0033dbd28b4774142a67369f41c11753555";
    sha256 = "1m5jqhflykya5h6s69ps6r70ffbsr6qkxdq1miqa68msshl21f9y";
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
    ./modules/programs/kakoune
    ./modules/programs/lieer
    ./modules/programs/mbsync
    ./modules/programs/neomutt
    ./modules/programs/newsboat
    ./modules/programs/qutebrowser
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
    ./modules/services/lieer
    ./modules/programs/rofi
    ./modules/services/polybar
    ./modules/services/sxhkd
    ./modules/services/window-managers/i3
    ./modules/systemd
    ./modules/targets
  ]);
}
