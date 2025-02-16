{ pkgs ? import <nixpkgs> { }, enableBig ? true }:

let

  lib = import ../modules/lib/stdlib-extended.nix pkgs.lib;

  nmtSrc = fetchTarball {
    url = "https://git.sr.ht/~rycee/nmt/archive/v0.5.1.tar.gz";
    sha256 = "0qhn7nnwdwzh910ss78ga2d00v42b0lspfd7ybl61mpfgz3lmdcj";
  };

  # Recursively replace each derivation in the given attribute set with the same
  # derivation but with the `outPath` attribute set to the string
  # `"@package-name@"`. This allows the tests to refer to derivations through
  # their values without establishing an actual dependency on the derivation
  # output.
  scrubDerivations = attrs:
    let
      scrubDerivation = name: value:
        let
          scrubbedValue = scrubDerivations value;

          newDrvAttrs = {
            buildScript = abort "no build allowed";

            outPath = builtins.traceVerbose ("${name} - got out path")
              "@${lib.getName value}@";

            # Prevent getOutput from descending into outputs
            outputSpecified = true;

            # Allow the original package to be used in derivation inputs
            __spliced = {
              buildHost = value;
              hostTarget = value;
            };
          };
        in if lib.isAttrs value then
          if lib.isDerivation value then
            scrubbedValue // newDrvAttrs
          else
            scrubbedValue
        else
          value;
    in lib.mapAttrs scrubDerivation attrs;

  # Globally unscrub a few selected packages that are used by a wide selection of tests.
  whitelist = let
    inner = self: super: {
      inherit (pkgs)
        coreutils jq desktop-file-utils diffutils findutils glibcLocales gettext
        gnugrep gnused shared-mime-info emptyDirectory
        # Needed by pretty much all tests that have anything to do with fish.
        babelfish fish;

      xorg =
        super.xorg.overrideScope (self: super: { inherit (pkgs.xorg) lndir; });
    };

    outer = self: super:
      inner self super // {
        buildPackages = super.buildPackages.extend inner;
      };
  in outer;

  scrubbedPkgs =
    let rawScrubbedPkgs = lib.makeExtensible (final: scrubDerivations pkgs);
    in builtins.traceVerbose "eval scrubbed nixpkgs"
    (rawScrubbedPkgs.extend whitelist);

  modules = import ../modules/modules.nix {
    inherit lib pkgs;
    check = false;
  } ++ [
    ({ config, ... }: {
      _module.args = {
        # Prevent the nixpkgs module from working. We want to minimize the number
        # of evaluations of Nixpkgs.
        pkgsPath = abort "pkgs path is unavailable in tests";
        realPkgs = pkgs;
        pkgs = let
          overlays = config.test.stubOverlays ++ lib.optionals
            (config.nixpkgs.overlays != null && config.nixpkgs.overlays != [ ])
            config.nixpkgs.overlays;
          stubbedPkgs = if overlays == [ ] then
            scrubbedPkgs
          else
            builtins.traceVerbose "eval overlayed nixpkgs"
            (lib.foldr (o: p: p.extend o) scrubbedPkgs overlays);
        in lib.mkImageMediaOverride stubbedPkgs;
      };

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
      manual.manpages.enable = lib.mkDefault false;

      imports = [ ./asserts.nix ./big-test.nix ./stubs.nix ];

      test.enableBig = enableBig;
    })
  ];

  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;

in import nmtSrc {
  inherit lib pkgs modules;
  testedAttrPath = [ "home" "activationPackage" ];
  tests = builtins.foldl' (a: b: a // (import b)) { } ([
    ./lib/generators
    ./lib/types
    ./modules/files
    ./modules/home-environment
    ./modules/misc/fontconfig
    ./modules/misc/manual
    ./modules/misc/nix
    ./modules/misc/specialisation
    ./modules/programs/aerc
    ./modules/programs/alacritty
    ./modules/programs/alot
    ./modules/programs/antidote
    ./modules/programs/aria2
    ./modules/programs/atuin
    ./modules/programs/autojump
    ./modules/programs/bacon
    ./modules/programs/bash
    ./modules/programs/bat
    ./modules/programs/borgmatic
    ./modules/programs/bottom
    ./modules/programs/broot
    ./modules/programs/browserpass
    ./modules/programs/btop
    ./modules/programs/carapace
    ./modules/programs/cava
    ./modules/programs/cmus
    ./modules/programs/comodoro
    ./modules/programs/darcs
    ./modules/programs/dircolors
    ./modules/programs/direnv
    ./modules/programs/emacs
    ./modules/programs/fastfetch
    ./modules/programs/feh
    ./modules/programs/fish
    ./modules/programs/gallery-dl
    ./modules/programs/gh
    ./modules/programs/gh-dash
    ./modules/programs/ghostty
    ./modules/programs/git
    ./modules/programs/git-cliff
    ./modules/programs/git-credential-oauth
    ./modules/programs/go
    ./modules/programs/gpg
    ./modules/programs/gradle
    ./modules/programs/granted
    ./modules/programs/helix
    ./modules/programs/himalaya
    ./modules/programs/htop
    ./modules/programs/hyfetch
    ./modules/programs/i3status
    ./modules/programs/irssi
    ./modules/programs/jujutsu
    ./modules/programs/joplin-desktop
    ./modules/programs/k9s
    ./modules/programs/kakoune
    ./modules/programs/khal
    ./modules/programs/khard
    ./modules/programs/kitty
    ./modules/programs/kubecolor
    ./modules/programs/lapce
    ./modules/programs/ledger
    ./modules/programs/less
    ./modules/programs/lesspipe
    ./modules/programs/lf
    ./modules/programs/lsd
    ./modules/programs/lieer
    ./modules/programs/man
    ./modules/programs/mbsync
    ./modules/programs/micro
    ./modules/programs/mise
    ./modules/programs/mpv
    ./modules/programs/mu
    ./modules/programs/mujmap
    ./modules/programs/ncmpcpp
    ./modules/programs/ne
    ./modules/programs/neomutt
    ./modules/programs/neovide
    ./modules/programs/neovim
    ./modules/programs/newsboat
    ./modules/programs/nheko
    ./modules/programs/nix-index
    ./modules/programs/nix-your-shell
    ./modules/programs/nnn
    ./modules/programs/nushell
    ./modules/programs/oh-my-posh
    ./modules/programs/openstackclient
    ./modules/programs/pandoc
    ./modules/programs/papis
    ./modules/programs/pay-respects
    ./modules/programs/pet
    ./modules/programs/pistol
    ./modules/programs/pls
    ./modules/programs/poetry
    ./modules/programs/powerline-go
    ./modules/programs/pubs
    ./modules/programs/pyenv
    ./modules/programs/qcal
    ./modules/programs/qutebrowser
    ./modules/programs/ranger
    ./modules/programs/readline
    ./modules/programs/rio
    ./modules/programs/ripgrep
    ./modules/programs/ruff
    ./modules/programs/sagemath
    ./modules/programs/sapling
    ./modules/programs/sbt
    ./modules/programs/scmpuff
    ./modules/programs/senpai
    ./modules/programs/sftpman
    ./modules/programs/sioyek
    ./modules/programs/sm64ex
    ./modules/programs/spotify-player
    ./modules/programs/ssh
    ./modules/programs/starship
    ./modules/programs/taskwarrior
    ./modules/programs/tealdeer
    ./modules/programs/texlive
    ./modules/programs/thefuck
    ./modules/programs/thunderbird
    ./modules/programs/tmate
    ./modules/programs/tmux
    ./modules/programs/topgrade
    ./modules/programs/translate-shell
    ./modules/programs/vifm
    ./modules/programs/vim-vint
    ./modules/programs/vscode
    ./modules/programs/watson
    ./modules/programs/wezterm
    ./modules/programs/yazi
    ./modules/programs/zed-editor
    ./modules/programs/zellij
    ./modules/programs/zk
    ./modules/programs/zplug
    ./modules/programs/zsh
    ./modules/services/gpg-agent
    ./modules/services/syncthing/common
    ./modules/xresources
  ] ++ lib.optionals isDarwin [
    ./modules/launchd
    ./modules/programs/aerospace
    ./modules/services/emacs-darwin
    ./modules/services/espanso-darwin
    ./modules/services/git-sync-darwin
    ./modules/services/imapnotify-darwin
    ./modules/services/nix-gc-darwin
    ./modules/services/ollama/darwin
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
    ./modules/programs/awscli
    ./modules/programs/beets # One test relies on services.mpd
    ./modules/programs/bemenu
    ./modules/programs/boxxy
    ./modules/programs/cavalier
    ./modules/programs/firefox/firefox.nix
    ./modules/programs/firefox/floorp.nix
    ./modules/programs/foot
    ./modules/programs/freetube
    ./modules/programs/fuzzel
    ./modules/programs/getmail
    ./modules/programs/gnome-shell
    ./modules/programs/gnome-terminal
    ./modules/programs/hexchat
    ./modules/programs/hyprlock
    ./modules/programs/i3blocks
    ./modules/programs/i3status-rust
    ./modules/programs/imv
    ./modules/programs/kodi
    ./modules/programs/looking-glass-client
    ./modules/programs/mangohud
    ./modules/programs/ncmpcpp-linux
    ./modules/programs/pqiv
    ./modules/programs/rbw
    ./modules/programs/rofi
    ./modules/programs/rofi-pass
    ./modules/programs/swaylock
    ./modules/programs/swayr
    ./modules/programs/terminator
    ./modules/programs/tofi
    ./modules/programs/waybar
    ./modules/programs/wlogout
    ./modules/programs/wofi
    ./modules/programs/wpaperd
    ./modules/programs/xmobar
    ./modules/programs/yambar
    ./modules/programs/yt-dlp
    ./modules/services/activitywatch
    ./modules/services/avizo
    ./modules/services/barrier
    ./modules/services/blanket
    ./modules/services/borgmatic
    ./modules/services/cachix-agent
    ./modules/services/cliphist
    ./modules/services/clipman
    ./modules/services/comodoro
    ./modules/services/copyq
    ./modules/services/conky
    ./modules/services/darkman
    ./modules/services/devilspie2
    ./modules/services/dropbox
    ./modules/services/emacs
    ./modules/services/espanso
    ./modules/services/flameshot
    ./modules/services/fluidsynth
    ./modules/services/fnott
    ./modules/services/fusuma
    ./modules/services/git-sync
    ./modules/services/glance
    ./modules/services/gromit-mpx
    ./modules/services/home-manager-auto-upgrade
    ./modules/services/hypridle
    ./modules/services/hyprpaper
    ./modules/services/imapnotify
    ./modules/services/kanshi
    ./modules/services/lieer
    ./modules/services/linux-wallpaperengine
    ./modules/services/mopidy
    ./modules/services/mpd
    ./modules/services/mpd-mpris
    ./modules/services/mpdris2
    ./modules/services/nix-gc
    ./modules/services/ollama/linux
    ./modules/services/osmscout-server
    ./modules/services/pantalaimon
    ./modules/services/parcellite
    ./modules/services/pass-secret-service
    ./modules/services/pasystray
    ./modules/services/pbgopy
    ./modules/services/picom
    ./modules/services/playerctld
    ./modules/services/podman-linux
    ./modules/services/polybar
    ./modules/services/recoll
    ./modules/services/redshift-gammastep
    ./modules/services/remmina
    ./modules/services/screen-locker
    ./modules/services/signaturepdf
    ./modules/services/snixembed
    ./modules/services/swayidle
    ./modules/services/swaync
    ./modules/services/swayosd
    ./modules/services/sxhkd
    ./modules/services/syncthing/linux
    ./modules/services/tldr-update
    ./modules/services/trayer
    ./modules/services/trayscale
    ./modules/services/twmn
    ./modules/services/udiskie
    ./modules/services/volnoti
    ./modules/services/window-managers/bspwm
    ./modules/services/window-managers/herbstluftwm
    ./modules/services/window-managers/hyprland
    ./modules/services/window-managers/i3
    ./modules/services/window-managers/river
    ./modules/services/window-managers/spectrwm
    ./modules/services/window-managers/sway
    ./modules/services/window-managers/wayfire
    ./modules/services/wlsunset
    ./modules/services/wob
    ./modules/services/xsettingsd
    ./modules/systemd
    ./modules/targets-linux
  ]);
}
