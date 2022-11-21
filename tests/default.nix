{ pkgs ? import <nixpkgs> {}, enableBig ? true }:

let

  lib = import ../modules/lib/stdlib-extended.nix pkgs.lib;

  nmt = fetchTarball {
    url =
      "https://gitlab.com/api/v4/projects/rycee%2Fnmt/repository/archive.tar.gz?sha=d83601002c99b78c89ea80e5e6ba21addcfe12ae";
    sha256 = "1xzwwxygzs1cmysg97hzd285r7n1g1lwx5y1ar68gwq07a1rczmv";
  };

  modules = import ../modules/modules.nix {
    inherit lib pkgs;
    check = false;
  } ++ [
    {
      # Bypass <nixpkgs> reference inside modules/modules.nix to make the test
      # suite more pure.
      _module.args.pkgsPath = pkgs.path;

      # Fix impurities. Without these some of the user's environment
      # will leak into the tests through `builtins.getEnv`.
      xdg.enable = true;
      home = {
        username = "hm-user";
        homeDirectory = "/home/hm-user";
        stateVersion = lib.mkDefault "18.09";
      };

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
    ./lib/generators
    ./lib/types
    ./modules/files
    ./modules/home-environment
    ./modules/misc/fontconfig
    ./modules/misc/nix
    ./modules/misc/specialization
    ./modules/programs/aerc
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
    ./modules/programs/btop
    ./modules/programs/dircolors
    ./modules/programs/direnv
    ./modules/programs/emacs
    ./modules/programs/feh
    ./modules/programs/fish
    ./modules/programs/gallery-dl
    ./modules/programs/gh
    ./modules/programs/git
    ./modules/programs/gpg
    ./modules/programs/helix
    ./modules/programs/himalaya
    ./modules/programs/htop
    ./modules/programs/hyfetch
    ./modules/programs/i3status
    ./modules/programs/irssi
    ./modules/programs/k9s
    ./modules/programs/kakoune
    ./modules/programs/kitty
    ./modules/programs/less
    ./modules/programs/lf
    ./modules/programs/lieer
    ./modules/programs/man
    ./modules/programs/mbsync
    ./modules/programs/micro
    ./modules/programs/mpv
    ./modules/programs/mu
    ./modules/programs/mujmap
    ./modules/programs/ncmpcpp
    ./modules/programs/ne
    ./modules/programs/neomutt
    ./modules/programs/newsboat
    ./modules/programs/nheko
    ./modules/programs/nix-index
    ./modules/programs/nnn
    ./modules/programs/nushell
    ./modules/programs/oh-my-posh
    ./modules/programs/pandoc
    ./modules/programs/papis
    ./modules/programs/pet
    ./modules/programs/pistol
    ./modules/programs/pls
    ./modules/programs/powerline-go
    ./modules/programs/pubs
    ./modules/programs/qutebrowser
    ./modules/programs/readline
    ./modules/programs/sagemath
    ./modules/programs/sbt
    ./modules/programs/scmpuff
    ./modules/programs/sioyek
    ./modules/programs/sm64ex
    ./modules/programs/ssh
    ./modules/programs/starship
    ./modules/programs/taskwarrior
    ./modules/programs/texlive
    ./modules/programs/tmate
    ./modules/programs/tmux
    ./modules/programs/topgrade
    ./modules/programs/vim-vint
    ./modules/programs/vscode
    ./modules/programs/watson
    ./modules/programs/wezterm
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
    ./modules/misc/editorconfig
    ./modules/misc/gtk
    ./modules/misc/numlock
    ./modules/misc/pam
    ./modules/misc/qt
    ./modules/misc/xdg
    ./modules/misc/xsession
    ./modules/programs/abook
    ./modules/programs/autorandr
    ./modules/programs/borgmatic
    ./modules/programs/firefox
    ./modules/programs/foot
    ./modules/programs/getmail
    ./modules/programs/gnome-terminal
    ./modules/programs/hexchat
    ./modules/programs/i3status-rust
    ./modules/programs/kodi
    ./modules/programs/looking-glass-client
    ./modules/programs/mangohud
    ./modules/programs/ncmpcpp-linux
    ./modules/programs/neovim   # Broken package dependency on Darwin.
    ./modules/programs/rbw
    ./modules/programs/rofi
    ./modules/programs/rofi-pass
    ./modules/programs/swaylock
    ./modules/programs/terminator
    ./modules/programs/thunderbird
    ./modules/programs/waybar
    ./modules/programs/wlogout
    ./modules/programs/xmobar
    ./modules/programs/yt-dlp
    ./modules/services/barrier
    ./modules/services/borgmatic
    ./modules/services/cachix-agent
    ./modules/services/clipman
    ./modules/services/devilspie2
    ./modules/services/dropbox
    ./modules/services/emacs
    ./modules/services/espanso
    ./modules/services/flameshot
    ./modules/services/fluidsynth
    ./modules/services/fnott
    ./modules/services/fusuma
    ./modules/services/git-sync
    ./modules/services/gpg-agent
    ./modules/services/gromit-mpx
    ./modules/services/home-manager-auto-upgrade
    ./modules/services/kanshi
    ./modules/services/lieer
    ./modules/services/mopidy
    ./modules/services/mpd
    ./modules/services/mpdris2
    ./modules/services/mpd-mpris
    ./modules/services/pantalaimon
    ./modules/services/parcellite
    ./modules/services/pass-secret-service
    ./modules/services/pbgopy
    ./modules/services/picom
    ./modules/services/playerctld
    ./modules/services/polybar
    ./modules/services/recoll
    ./modules/services/redshift-gammastep
    ./modules/services/screen-locker
    ./modules/services/swayidle
    ./modules/services/sxhkd
    ./modules/services/syncthing
    ./modules/services/trayer
    ./modules/services/twmn
    ./modules/services/udiskie
    ./modules/services/window-managers/bspwm
    ./modules/services/window-managers/herbstluftwm
    ./modules/services/window-managers/i3
    ./modules/services/window-managers/spectrwm
    ./modules/services/window-managers/sway
    ./modules/services/wlsunset
    ./modules/services/xsettingsd
    ./modules/systemd
    ./modules/targets-linux
  ]);
}
