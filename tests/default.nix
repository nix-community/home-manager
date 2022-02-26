{ pkgs ? import <nixpkgs> {}, enableBig ? true }:

let

  lib = import ../modules/lib/stdlib-extended.nix pkgs.lib;

  nmt = pkgs.fetchFromGitLab {
    owner = "rycee";
    repo = "nmt";
    rev = "89924d8e6e0fcf866a11324d32c6bcaa89cda506";
    sha256 = "02wzrbmpdpgig58a1rhz8sb0p2rvbapnlcmhi4d4bi8w9md6pmdl";
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

      imports = [ ./asserts.nix ./big-test.nix ./stubs.nix ];

      test.enableBig = enableBig;
    }
  ];

  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;

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
    ./modules/programs/atuin
    ./modules/programs/autojump
    ./modules/programs/bash
    ./modules/programs/bat
    ./modules/programs/bottom
    ./modules/programs/broot
    ./modules/programs/browserpass
    ./modules/programs/dircolors
    ./modules/programs/direnv
    ./modules/programs/emacs
    ./modules/programs/feh
    ./modules/programs/fish
    ./modules/programs/gh
    ./modules/programs/git
    ./modules/programs/gpg
    ./modules/programs/helix
    ./modules/programs/himalaya
    ./modules/programs/htop
    ./modules/programs/i3status
    ./modules/programs/irssi
    ./modules/programs/kakoune
    ./modules/programs/kitty
    ./modules/programs/less
    ./modules/programs/lf
    ./modules/programs/lieer
    ./modules/programs/man
    ./modules/programs/mbsync
    ./modules/programs/mpv
    ./modules/programs/ncmpcpp
    ./modules/programs/ne
    ./modules/programs/neomutt
    ./modules/programs/newsboat
    ./modules/programs/nix-index
    ./modules/programs/nnn
    ./modules/programs/nushell
    ./modules/programs/pandoc
    ./modules/programs/pet
    ./modules/programs/powerline-go
    ./modules/programs/qutebrowser
    ./modules/programs/readline
    ./modules/programs/sagemath
    ./modules/programs/sbt
    ./modules/programs/scmpuff
    ./modules/programs/sm64ex
    ./modules/programs/ssh
    ./modules/programs/starship
    ./modules/programs/taskwarrior
    ./modules/programs/texlive
    ./modules/programs/tmux
    ./modules/programs/topgrade
    ./modules/programs/vscode
    ./modules/programs/watson
    ./modules/programs/zplug
    ./modules/programs/zsh
    ./modules/xresources
  ] ++ lib.optionals isDarwin [
    ./modules/launchd
    ./modules/targets-darwin
  ] ++ lib.optionals isLinux [
    ./modules/config/i18n
    ./modules/i18n/input-method
    ./modules/misc/debug
    ./modules/misc/gtk
    ./modules/misc/numlock
    ./modules/misc/pam
    ./modules/misc/qt
    ./modules/misc/xdg
    ./modules/misc/xsession
    ./modules/programs/abook
    ./modules/programs/autorandr
    ./modules/programs/firefox
    ./modules/programs/foot
    ./modules/programs/getmail
    ./modules/programs/gnome-terminal
    ./modules/programs/hexchat
    ./modules/programs/i3status-rust
    ./modules/programs/kodi
    ./modules/programs/mangohud
    ./modules/programs/ncmpcpp-linux
    ./modules/programs/neovim   # Broken package dependency on Darwin.
    ./modules/programs/rbw
    ./modules/programs/rofi
    ./modules/programs/rofi-pass
    ./modules/programs/terminator
    ./modules/programs/waybar
    ./modules/programs/xmobar
    ./modules/services/barrier
    ./modules/services/devilspie2
    ./modules/services/dropbox
    ./modules/services/emacs
    ./modules/services/espanso
    ./modules/services/flameshot
    ./modules/services/fluidsynth
    ./modules/services/fnott
    ./modules/services/git-sync
    ./modules/services/gpg-agent
    ./modules/services/gromit-mpx
    ./modules/services/home-manager-auto-upgrade
    ./modules/services/kanshi
    ./modules/services/lieer
    ./modules/services/pantalaimon
    ./modules/services/pbgopy
    ./modules/services/playerctld
    ./modules/services/polybar
    ./modules/services/redshift-gammastep
    ./modules/services/screen-locker
    ./modules/services/swayidle
    ./modules/services/sxhkd
    ./modules/services/syncthing
    ./modules/services/trayer
    ./modules/services/twmn
    ./modules/services/window-managers/bspwm
    ./modules/services/window-managers/herbstluftwm
    ./modules/services/window-managers/i3
    ./modules/services/window-managers/leftwm
    ./modules/services/window-managers/sway
    ./modules/services/wlsunset
    ./modules/services/xsettingsd
    ./modules/systemd
    ./modules/targets-linux
  ]);
}
