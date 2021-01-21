{ pkgs ? import <nixpkgs> {} }:

let

  lib = import ../modules/lib/stdlib-extended.nix pkgs.lib;

  nmt = pkgs.fetchFromGitLab {
    owner = "rycee";
    repo = "nmt";
    rev = "76dbb0d2d8910c8e7b7d0a21e9b3089621793d3f";
    sha256 = "196hskx8c3dkxgiqh5lg52g9wz9lq81f7jn24vn8jj44rh3qw9cg";
  };

  modules = import ../modules/modules.nix {
    inherit lib pkgs;
    check = false;
  } ++ [
    {
      # Fix impurities. Without these some of the user's environment
      # will leak into the tests through `builtins.getEnv`.
      xdg.enable = true;
      home.username = "hm-user";
      home.homeDirectory = "/home/hm-user";

      # Avoid including documentation since this will cause
      # unnecessary rebuilds of the tests.
      manual.manpages.enable = false;

      imports = [ ./asserts.nix ];
    }
  ];

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
    ./modules/programs/alot
    ./modules/programs/aria2
    ./modules/programs/autojump
    ./modules/programs/bash
    ./modules/programs/browserpass
    ./modules/programs/dircolors
    ./modules/programs/direnv
    ./modules/programs/feh
    ./modules/programs/fish
    ./modules/programs/gh
    ./modules/programs/git
    ./modules/programs/gpg
    ./modules/programs/i3status
    ./modules/programs/kakoune
    ./modules/programs/lf
    ./modules/programs/lieer
    ./modules/programs/man
    ./modules/programs/mbsync
    ./modules/programs/ncmpcpp
    ./modules/programs/ne
    ./modules/programs/neomutt
    ./modules/programs/newsboat
    ./modules/programs/nushell
    ./modules/programs/powerline-go
    ./modules/programs/qutebrowser
    ./modules/programs/readline
    ./modules/programs/ssh
    ./modules/programs/starship
    ./modules/programs/texlive
    ./modules/programs/tmux
    ./modules/programs/vscode
    ./modules/programs/zplug
    ./modules/programs/zsh
    ./modules/xresources
  ] ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
    ./modules/targets-darwin
  ] ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
    ./modules/misc/debug
    ./modules/misc/numlock
    ./modules/misc/pam
    ./modules/misc/xdg
    ./modules/misc/xsession
    ./modules/programs/abook
    ./modules/programs/autorandr
    ./modules/programs/firefox
    ./modules/programs/getmail
    ./modules/programs/i3status-rust
    ./modules/programs/ncmpcpp-linux
    ./modules/programs/neovim   # Broken package dependency on Darwin.
    ./modules/programs/rofi
    ./modules/programs/rofi-pass
    ./modules/programs/waybar
    ./modules/services/dropbox
    ./modules/services/emacs
    ./modules/services/fluidsynth
    ./modules/services/kanshi
    ./modules/services/lieer
    ./modules/services/pbgopy
    ./modules/services/polybar
    ./modules/services/sxhkd
    ./modules/services/window-managers/i3
    ./modules/services/window-managers/sway
    ./modules/services/wlsunset
    ./modules/systemd
    ./modules/targets-linux
  ]);
}
