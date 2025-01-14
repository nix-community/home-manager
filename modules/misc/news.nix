{ config, lib, options, pkgs, ... }:
with lib;
let
  cfg = config.news;

  hostPlatform = pkgs.stdenv.hostPlatform;

  entryModule = types.submodule ({ config, ... }: {
    options = {
      id = mkOption {
        internal = true;
        type = types.str;
        description = ''
          A unique entry identifier. By default it is a base16
          formatted hash of the entry message.
        '';
      };

      time = mkOption {
        internal = true;
        type = types.str;
        example = "2017-07-10T21:55:04+00:00";
        description = ''
          News entry time stamp in ISO-8601 format. Must be in UTC
          (ending in '+00:00').
        '';
      };

      condition = mkOption {
        internal = true;
        default = true;
        description = "Whether the news entry should be active.";
      };

      message = mkOption {
        internal = true;
        type = types.str;
        description = "The news entry content.";
      };
    };

    config = { id = mkDefault (builtins.hashString "sha256" config.message); };
  });
in {
  meta.maintainers = [ maintainers.rycee ];

  options = {
    news = {
      display = mkOption {
        type = types.enum [ "silent" "notify" "show" ];
        default = "notify";
        description = ''
          How unread and relevant news should be presented when
          running {command}`home-manager build` and
          {command}`home-manager switch`.

          The options are

          `silent`
          : Do not print anything during build or switch. The
            {command}`home-manager news` command still
            works for viewing the entries.

          `notify`
          : The number of unread and relevant news entries will be
            printed to standard output. The {command}`home-manager
            news` command can later be used to view the entries.

          `show`
          : A pager showing unread news entries is opened.
        '';
      };

      entries = mkOption {
        internal = true;
        type = types.listOf entryModule;
        default = [ ];
        description = "News entries.";
      };

      json = {
        output = mkOption {
          internal = true;
          type = types.package;
          description = "The generated JSON file package.";
        };
      };
    };
  };

  config = {
    news.json.output = pkgs.writeText "hm-news.json"
      (builtins.toJSON { inherit (cfg) display entries; });

    # Add news entries in chronological order (i.e., latest time
    # should be at the bottom of the list). The time should be
    # formatted as given in the output of
    #
    #     date --iso-8601=second --universal
    #
    # On darwin (or BSD like systems) use
    #
    #     date -u +'%Y-%m-%dT%H:%M:%S+00:00'
    news.entries = [
      {
        time = "2021-06-02T04:24:10+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.xidlehook'.
        '';
      }

      {
        time = "2021-06-07T20:44:00+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.pantalaimon'.
        '';
      }

      {
        time = "2021-06-12T05:00:22+00:00";
        message = ''
          A new module is available: 'programs.mangohud'.
        '';
      }

      {
        time = "2021-06-16T01:26:16+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          The xmonad module now compiles the configuration before
          linking the binary to the place xmonad expects to find
          the compiled configuration (the binary).

          This breaks recompilation of xmonad (i.e. the 'q' binding or
          'xmonad --recompile').

          If this behavior is undesirable, do not use the
          'xsession.windowManager.xmonad.config' option. Instead, set the
          contents of the configuration file with
          'home.file.".xmonad/config.hs".text = "content of the file"'
          or 'home.file.".xmonad/config.hs".source = ./path-to-config'.
        '';
      }

      {
        time = "2021-06-24T22:36:11+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'i18n.inputMethod'.
        '';
      }

      {
        time = "2021-06-22T14:43:53+00:00";
        message = ''
          A new module is available: 'programs.himalaya'.
        '';
      }

      {
        time = "2021-07-11T17:45:56+00:00";
        message = ''
          A new module is available: 'programs.sm64ex'.
        '';
      }

      {
        time = "2021-07-15T13:38:32+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.xsettingsd'.
        '';
      }

      {
        time = "2021-07-14T20:06:18+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.volnoti'.
        '';
      }

      {
        time = "2021-07-23T22:22:31+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.trayer'.
        '';
      }

      {
        time = "2021-07-19T01:30:46+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.notify-osd'.
        '';
      }

      {
        time = "2021-08-10T21:28:40+00:00";
        message = ''
          A new module is available: 'programs.java'.
        '';
      }

      {
        time = "2021-08-11T13:55:51+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.easyeffects'.
        '';
      }

      {
        time = "2021-08-16T21:59:02+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.git-sync'.
        '';
      }

      {
        time = "2021-08-26T06:40:59+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.fnott'.
        '';
      }

      {
        time = "2021-08-31T18:44:26+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.betterlockscreen'.
        '';
      }

      {
        time = "2021-09-14T21:31:03+00:00";
        message = ''
          A new module is available: 'programs.bottom'.
        '';
      }

      {
        time = "2021-09-23T17:04:48+00:00";
        condition = hostPlatform.isLinux
          && config.services.screen-locker.enable;
        message = ''
          'xautolock' is now optional in 'services.screen-locker', and the
          'services.screen-locker' options have been reorganized for clarity.
          See the 'xautolock' and 'xss-lock' options modules in
          'services.screen-locker'.
        '';
      }

      {
        time = "2021-10-05T20:55:07+00:00";
        message = ''
          A new module is available: 'programs.atuin'.
        '';
      }

      {
        time = "2021-10-05T22:15:00+00:00";
        message = ''
          A new module is available: 'programs.nnn'.
        '';
      }

      {
        time = "2021-10-08T22:16:50+00:00";
        condition = hostPlatform.isLinux && config.programs.rofi.enable;
        message = ''
          Rofi version '1.7.0' removed many options that were used by the module
          and replaced them with custom themes, which are more flexible and
          powerful.

          You can replicate your old configuration by moving those options to
          'programs.rofi.theme'. Keep in mind that the syntax is different so
          you may need to do some changes.
        '';
      }

      {
        time = "2021-10-23T17:12:22+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'programs.hexchat'.
        '';
      }

      {
        time = "2021-11-21T17:21:04+00:00";
        condition = config.wayland.windowManager.sway.enable;
        message = ''
          A new module is available: 'wayland.windowManager.sway.swaynag'.
        '';
      }

      {
        time = "2021-11-23T20:26:37+00:00";
        condition = config.programs.taskwarrior.enable;
        message = ''
          Taskwarrior version 2.6.0 respects XDG Specification for the config
          file now. Option 'programs.taskwarrior.config' and friends now
          generate the config file at '$XDG_CONFIG_HOME/task/taskrc' instead of
          '~/.taskrc'.
        '';
      }

      {
        time = "2021-11-30T22:28:12+00:00";
        message = ''
          A new module is available: 'programs.less'.
        '';
      }

      {
        time = "2021-11-29T15:15:59+00:00";
        condition = hostPlatform.isDarwin;
        message = ''
          The option 'targets.darwin.defaults."com.apple.menuextra.battery".ShowPercent'
          has been deprecated since it no longer works on the latest version of
          macOS.
        '';
      }

      {
        time = "2021-12-02T02:59:59+00:00";
        condition = config.programs.waybar.enable;
        message = ''
          The Waybar module now allows defining modules directly under the 'settings'
          option instead of nesting the modules under 'settings.modules'.
          The Waybar module will also stop reporting errors about unused or misnamed
          modules.
        '';
      }

      {
        time = "2021-12-08T10:23:42+00:00";
        condition = config.programs.less.enable;
        message = ''
          The 'lesskey' configuration file is now stored under
          '$XDG_CONFIG_HOME/lesskey' since it is fully supported upstream
          starting from v596.
        '';
      }

      {
        time = "2021-12-10T23:19:57+00:00";
        message = ''
          A new module is available: 'programs.sqls'.
        '';
      }

      {
        time = "2021-12-11T11:55:12+00:00";
        message = ''
          A new module is available: 'programs.navi'.
        '';
      }

      {
        time = "2021-12-11T16:07:00+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.gromit-mpx'.
        '';
      }

      {
        time = "2021-12-12T17:09:38+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.opensnitch-ui'.
        '';
      }

      {
        time = "2021-12-21T22:17:30+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.systembus-notify'.
        '';
      }

      {
        time = "2021-12-31T09:39:20+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'xsession.windowManager.herbstluftwm'.
        '';
      }

      {
        time = "2022-01-03T10:34:45+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.swayidle'.
        '';
      }

      {
        time = "2022-01-11T12:26:43+00:00";
        message = ''
          A new module is available: 'programs.sagemath'.
        '';
      }

      {
        time = "2022-01-22T14:36:25+00:00";
        message = ''
          A new module is available: 'programs.helix'.
        '';
      }

      {
        time = "2022-01-22T15:12:20+00:00";
        message = ''
          A new module is available: 'programs.watson'.
        '';
      }

      {
        time = "2022-01-22T15:33:42+00:00";
        message = ''
          A new module is available: 'programs.timidity'.
        '';
      }

      {
        time = "2022-01-22T16:54:31+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'programs.tint2'.
        '';
      }

      {
        time = "2022-01-22T17:39:20+00:00";
        message = ''
          A new module is available: 'programs.pandoc'.
        '';
      }

      {
        time = "2022-01-26T22:08:29+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'programs.kodi'.
        '';
      }

      {
        time = "2022-02-03T23:23:49+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.twmn'.
        '';
      }

      {
        time = "2022-02-16T23:50:35+00:00";
        message = ''
          A new module is available: 'programs.zellij'.
        '';
      }

      {
        time = "2022-02-17T17:12:46+00:00";
        message = ''
          A new module is available: 'programs.eww'.
        '';
      }

      {
        time = "2022-02-17T23:11:13+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.espanso'.
        '';
      }

      {
        time = "2022-02-24T22:35:22+00:00";
        message = ''
          A new module is available: 'programs.gitui'.
        '';
      }

      {
        time = "2022-02-26T09:28:57+00:00";
        condition = hostPlatform.isDarwin;
        message = ''
          A new module is available: 'launchd.agents'

          Use this to enable services based on macOS LaunchAgents.
        '';
      }

      {
        time = "2022-03-06T08:50:32+00:00";
        message = ''
          A new module is available: 'programs.just'.
        '';
      }

      {
        time = "2022-03-06T09:40:17+00:00";
        message = ''
          A new module is available: 'programs.pubs'.
        '';
      }

      {
        time = "2022-03-13T20:59:38+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.fusuma'.
        '';
      }

      {
        time = "2022-05-02T20:55:46+00:00";
        message = ''
          A new module is available: 'programs.tealdeer'.
        '';
      }

      {
        time = "2022-05-18T22:09:45+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.mopidy'.
        '';
      }

      {
        time = "2022-06-21T22:29:37+00:00";
        message = ''
          A new module is available: 'programs.mujmap'.
        '';
      }

      {
        time = "2022-06-24T17:18:32+00:00";
        message = ''
          A new module is available: 'programs.micro'.
        '';
      }

      {
        time = "2022-06-24T22:40:27+00:00";
        message = ''
          A new module is available: 'programs.pistol'.
        '';
      }

      {
        time = "2022-06-26T19:29:25+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.sctd'.
        '';
      }

      {
        time = "2022-07-12T08:59:50+00:00";
        condition = config.services.picom.enable;
        message = ''
          The 'services.picom' module has been refactored to use structural
          settings.

          As a result 'services.picom.extraOptions' has been removed in favor of
          'services.picom.settings'. Also, 'services.picom.blur*' were removed
          since upstream changed the blur settings to be more flexible. You can
          migrate the blur settings to use 'services.picom.settings' instead.
        '';
      }

      {
        time = "2022-07-13T13:28:54+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'programs.librewolf'.
        '';
      }

      {
        time = "2022-07-24T13:17:01+00:00";
        condition = hostPlatform.isDarwin;
        message = ''
          A new option is available: 'targets.darwin.currentHostDefaults'.

          This exposes macOS preferences that are available through the
          'defaults -currentHost' command.
        '';
      }

      {
        time = "2022-07-25T11:29:14+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'xsession.windowManager.spectrwm'.
        '';
      }

      {
        time = "2022-07-27T12:22:37+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.recoll'.
        '';
      }

      {
        time = "2022-08-01T16:35:28+00:00";
        message = ''
          A new module is available: 'programs.hyfetch'.
        '';
      }

      {
        time = "2022-08-07T09:07:35+00:00";
        message = ''
          A new module is available: 'programs.wezterm'.
        '';
      }

      {
        time = "2022-08-08T16:11:22+00:00";
        message = ''
          A new module is available: 'programs.bashmount'.
        '';
      }

      {
        time = "2022-08-25T21:01:37+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.pueue'.
        '';
      }

      {
        time = "2022-09-05T12:33:11+00:00";
        message = ''
          A new module is available: 'programs.btop'.
        '';
      }

      {
        time = "2022-09-05T11:05:25+00:00";
        message = ''
          A new module is available: 'editorconfig'.
        '';
      }

      {
        time = "2022-09-08T15:41:46+00:00";
        message = ''
          A new module is available: 'programs.nheko'.
        '';
      }

      {
        time = "2022-09-08T17:50:43+00:00";
        message = ''
          A new module is available: 'programs.yt-dlp'.
        '';
      }

      {
        time = "2022-09-09T09:55:50+00:00";
        message = ''
          A new module is available: 'programs.gallery-dl'.
        '';
      }

      {
        time = "2022-09-21T22:42:42+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'xsession.windowManager.fluxbox'.
        '';
      }

      {
        time = "2022-09-25T21:00:05+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.safeeyes'.
        '';
      }

      {
        time = "2022-09-25T22:22:17+00:00";
        message = ''
          A new module is available: 'programs.tmate'.
        '';
      }

      {
        time = "2022-09-29T13:43:02+00:00";
        message = ''
          A new module is available: 'programs.pls'.
        '';
      }

      {
        time = "2022-10-06T23:06:08+00:00";
        message = ''
          A new module is available: 'programs.ledger'.
        '';
      }

      {
        time = "2022-10-06T23:19:10+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'programs.havoc'.
        '';
      }

      {
        time = "2022-10-12T23:10:48+00:00";
        message = ''
          A new module is available: 'programs.discocss'.
        '';
      }

      {
        time = "2022-10-16T19:49:46+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          Two new modules are available:

            - 'programs.borgmatic' and
            - 'services.borgmatic'.

          use the first to configure the borgmatic tool and the second if you
          want to automatically run scheduled backups.
        '';
      }

      {
        time = "2022-10-18T08:07:43+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'programs.looking-glass-client'.
        '';
      }

      {
        time = "2022-10-22T17:52:30+00:00";
        condition = config.programs.firefox.enable;
        message = ''
          It is now possible to configure the default search engine in Firefox
          with

            programs.firefox.profiles.<name>.search.default

          and add custom engines with

            programs.firefox.profiles.<name>.search.engines.

          It is also recommended to set

            programs.firefox.profiles.<name>.search.force = true

          since Firefox will replace the symlink for the search configuration on
          every launch, but note that you'll lose any existing configuration by
          enabling this.
        '';
      }

      {
        time = "2022-10-24T22:05:27+00:00";
        message = ''
          A new module is available: 'programs.k9s'.
        '';
      }

      {
        time = "2022-11-01T23:57:50+00:00";
        message = ''
          A new module is available: 'programs.oh-my-posh'.
        '';
      }

      {
        time = "2022-11-02T10:56:14+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'xfconf'.
        '';
      }

      {
        time = "2022-11-04T14:56:46+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'programs.thunderbird'.
        '';
      }

      {
        time = "2022-11-13T09:05:51+00:00";
        condition = hostPlatform.isDarwin;
        message = ''
          A new module is available: 'programs.thunderbird'.

          Please note that the Thunderbird packages provided by Nix are
          currently not working on macOS. The module can still be used to manage
          configuration files by installing Thunderbird manually and setting the
          'programs.thunderbird.package' option to a dummy package, for example
          using 'pkgs.runCommand'.

          This module requires you to set the following environment variables
          when using an installation of Thunderbird that is not provided by Nix:

            export MOZ_LEGACY_PROFILES=1
            export MOZ_ALLOW_DOWNGRADE=1
        '';
      }

      {
        time = "2022-11-27T13:14:01+00:00";
        condition = config.programs.ssh.enable;
        message = ''
          'programs.ssh.matchBlocks.*' now supports literal 'Match' blocks via
          'programs.ssh.matchBlocks.*.match' option as an alternative to plain
          'Host' blocks
        '';
      }

      {
        time = "2022-12-16T15:01:20+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.megasync'.
        '';
      }

      {
        time = "2022-12-25T08:41:32+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.cachix-agent'.
        '';
      }

      {
        time = "2022-12-28T21:48:22+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.clipman'.
        '';
      }

      {
        time = "2023-01-07T10:47:03+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          'xsession.windowManager.i3.config.[window|floating].titlebar' and
          'wayland.windowManager.sway.config.[window|floating].titlebar' now default to 'true'.
        '';
      }

      {
        time = "2023-01-28T17:35:49+00:00";
        message = ''
          A new module is available: 'programs.papis'.
        '';
      }

      {
        time = "2023-01-30T10:39:11+00:00";
        message = ''
          A new module is available: 'programs.wlogout'.
        '';
      }

      {
        time = "2023-01-31T22:08:41+00:00";
        message = ''
          A new module is available: 'programs.rbenv'.
        '';
      }

      {
        time = "2023-02-02T20:49:05+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.autorandr'.
        '';
      }

      {
        time = "2023-02-20T22:31:23+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.mpd-mpris'.
        '';
      }

      {
        time = "2023-02-22T22:16:37+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.avizo'.
        '';
      }

      {
        time = "2023-03-16:12:00+00:00";
        condition = config.programs.i3status-rust.enable;
        message = ''
          Module 'i3status-rust' was updated to support the new configuration
          format from 0.30.x releases, that introduces many breaking changes.
          The documentation was updated with examples from 0.30.x to help
          the transition.

          See https://github.com/greshake/i3status-rust/blob/v0.30.0/NEWS.md
          for instructions on how to migrate.

          Users that don't want to migrate yet can set
          'programs.i3status-rust.package' to an older version.
        '';
      }

      {
        time = "2023-03-22T07:20:00+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.listenbrainz-mpd'.
        '';
      }

      {
        time = "2023-03-22T07:31:38+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.copyq'.
        '';
      }

      {
        time = "2023-03-25T11:03:24+00:00";
        condition = hostPlatform.isDarwin;
        message = ''
          A new module is available: 'services.syncthing'.
        '';
      }

      {
        time = "2023-03-25T14:53:57+00:00";
        message = ''
          A new module is available: 'programs.hstr'.
        '';
      }

      {
        time = "2023-04-18T06:28:31+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.batsignal'.
        '';
      }

      {
        time = "2023-04-19T15:33:07+00:00";
        message = ''
          A new module is available: 'programs.mr'.
        '';
      }

      {
        time = "2023-04-28T19:59:23+00:00";
        message = ''
          A new module is available: 'programs.jujutsu'.
        '';
      }

      {
        time = "2023-05-09T16:06:56+00:00";
        message = ''
          A new module is available: 'programs.git-cliff'.
        '';
      }

      {
        time = "2023-05-12T21:31:05+00:00";
        message = ''
          A new module is available: 'programs.translate-shell'.
        '';
      }

      {
        time = "2023-05-13T13:51:18+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'programs.fuzzel'.
        '';
      }

      {
        time = "2023-05-13T14:34:21+00:00";
        condition = config.programs.ssh.enable;
        message = ''
          The module 'programs.ssh' can now install an SSH client. The installed
          client is controlled by the 'programs.ssh.package` option, which
          defaults to 'null'.
        '';
      }

      {
        time = "2023-05-18T21:03:30+00:00";
        message = ''
          A new module is available: 'programs.script-directory'.
        '';
      }

      {
        time = "2023-06-03T22:19:32+00:00";
        message = ''
          A new module is available: 'programs.ripgrep'.
        '';
      }

      {
        time = "2023-06-07T06:01:16+00:00";
        message = ''
          A new module is available: 'programs.rtx'.
        '';
      }

      {
        time = "2023-06-07T12:16:55+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'programs.imv'.
        '';
      }

      {
        time = "2023-06-09T19:13:39+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'programs.boxxy'.
        '';
      }

      {
        time = "2020-04-26T13:32:17+00:00";
        message = ''
          A number of new modules are available:

            - 'accounts.calendar',
            - 'accounts.contact',
            - 'programs.khal',
            - 'programs.vdirsyncer', and
            - 'services.vdirsyncer' (Linux only).

          The two first modules offer a number of options for
          configuring calendar and contact accounts. This includes,
          for example, information about carddav and caldav servers.

          The khal and vdirsyncer modules make use of this new account
          infrastructure.

          Note, these module are still somewhat experimental and their
          structure should not be seen as final, some modifications
          may be necessary as new modules are added.
        '';
      }

      {
        time = "2023-06-14T21:25:34+00:00";
        message = ''
          A new module is available: 'programs.git-credential-oauth'.
        '';
      }

      {
        time = "2023-06-14T21:41:22+00:00";
        message = ''
          Two new modules are available:

            - 'programs.comodoro' and
            - 'services.comodoro'
        '';
      }

      {
        time = "2023-06-15T16:30:00+00:00";
        condition = config.qt.enable;
        message = ''
          Qt module now supports new platform themes and styles, and has partial
          support for Qt6. For example, you can now use:

          - `qt.platformTheme = "kde"`: set a theme using Plasma. You can
          configure it by setting `~/.config/kdeglobals` file;
          - `qt.platformTheme = "qtct"`: set a theme using qt5ct/qt6ct. You
          can control it by using the `qt5ct` and `qt6ct` applications;
          - `qt.style.name = "kvantum"`: override the style by using themes
          written in SVG. Supports many popular themes.
        '';
      }

      {
        time = "2023-06-17T22:18:22+00:00";
        condition = config.programs.zsh.enable;
        message = ''
          A new module is available: 'programs.zsh.antidote'
        '';
      }

      {
        time = "2023-06-30T14:46:22+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.ssh-agent'
        '';
      }

      {
        time = "2023-07-08T08:27:41+00:00";
        message = ''
          A new modules is available: 'programs.darcs'
        '';
      }

      {
        time = "2023-07-08T09:21:06+00:00";
        message = ''
          A new module is available: 'programs.pyenv'.
        '';
      }

      {
        time = "2023-07-08T09:44:56+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.swayosd'
        '';
      }

      {
        time = "2023-07-20T21:56:49+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'wayland.windowManager.hyprland'
        '';
      }

      {
        time = "2023-07-24T10:38:23+00:00";
        message = ''
          A new module is available: 'programs.gh-dash'
        '';
      }

      {
        time = "2023-07-25T07:16:09+00:00";
        condition = hostPlatform.isDarwin;
        message = ''
          A new module is available: 'services.git-sync'.
        '';
      }

      {
        time = "2023-08-15T15:45:45+00:00";
        message = ''
          A new module is available: 'programs.xplr'.
        '';
      }

      {
        time = "2023-08-16T15:43:30+00:00";
        message = ''
          A new module is available: 'programs.pqiv'.
        '';
      }

      {
        time = "2023-08-22T16:06:52+00:00";
        message = ''
          A new module is available: 'programs.qcal'.
        '';
      }

      {
        time = "2023-08-23T12:01:06+00:00";
        message = ''
          A new module is available: 'programs.yazi'.
        '';
      }

      {
        time = "2023-09-05T06:38:05+00:00";
        message = ''
          A new module is available: 'programs.carapace'.
        '';
      }

      {
        time = "2023-09-07T14:52:19+00:00";
        message = ''
          A new module is available: 'programs.eza'.
        '';
      }

      {
        time = "2023-09-18T11:44:11+00:00";
        message = ''
          A new module is available: 'programs.rio'.

          Rio is a hardware-accelerated GPU terminal emulator powered by WebGPU.
        '';
      }

      {
        time = "2023-09-24T10:06:47+00:00";
        message = ''
          A new module is available: 'programs.bacon'.
        '';
      }

      {
        time = "2023-09-30T07:47:23+00:00";
        message = ''
          A new module is available: 'programs.awscli'.
        '';
      }

      {
        time = "2023-10-01T07:23:26+00:00";
        message = ''
          A new module is available: 'programs.wpaperd'.
        '';
      }

      {
        time = "2023-10-01T07:28:45+00:00";
        message = ''
          A new module is available: 'programs.khard'.
        '';
      }

      {
        time = "2023-10-04T06:06:08+00:00";
        condition = config.programs.zsh.enable;
        message = ''
          A new module is available: 'programs.zsh.zsh-abbr'
        '';
      }

      {
        time = "2023-10-04T06:44:15+00:00";
        message = ''
          A new module is available: 'programs.thefuck'.
        '';
      }

      {
        time = "2023-10-04T18:35:42+00:00";
        message = ''
          A new module is available: 'programs.openstackclient'.
        '';
      }

      {
        time = "2023-10-17T06:33:24+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.darkman'.
        '';
      }

      {
        time = "2023-10-24T06:14:53+00:00";
        message = ''
          A new module is available: 'programs.cava'.
        '';
      }

      {
        time = "2023-11-01T21:18:20+00:00";
        message = ''
          A new module is available: 'programs.granted'.
        '';
      }

      {
        time = "2023-11-22T22:42:16+00:00";
        message = ''
          A new module is available: 'programs.ruff'.
        '';
      }

      {
        time = "2023-11-26T23:18:01+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.signaturepdf'.
        '';
      }

      {
        time = "2023-12-10T08:43:02+00:00";
        condition = config.wayland.windowManager.hyprland.settings ? source;
        message = ''
          Entries in

            wayland.windowManager.hyprland.settings.source

          are now placed at the start of the configuration file. If you relied
          on the previous placement of the 'source' entries, please set

             wayland.windowManager.hyprland.sourceFirst = false

          to keep the previous behaviour.
        '';
      }

      {
        time = "2023-12-19T22:57:52+00:00";
        message = ''
          A new module is available: 'programs.sapling'.
        '';
      }

      {
        time = "2023-12-20T11:41:10+00:00";
        message = ''
          A new module is available: 'programs.gradle'.
        '';
      }

      {
        time = "2023-12-28T08:28:26+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.osmscout-server'.
        '';
      }

      {
        time = "2023-12-28T13:01:15+00:00";
        message = ''
          A new module is available: 'programs.sftpman'.
        '';
      }

      {
        time = "2023-12-29T08:22:40+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'programs.bemenu'.
        '';
      }

      {
        time = "2024-01-01T09:09:42+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'programs.i3blocks'.
        '';
      }

      {
        time = "2024-01-03T19:25:09+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'xdg.portal'.
        '';
      }

      {
        time = "2024-01-20T23:45:07+00:00";
        message = ''
          A new module is available: 'programs.mise'.

          This module replaces 'programs.rtx', which has been removed.
        '';
      }

      {
        time = "2024-01-27T22:53:00+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.wob'.
        '';
      }

      {
        time = "2024-02-05T22:33:54+00:00";
        message = ''
          A new module is available: 'services.arrpc'
        '';
      }

      {
        time = "2024-02-05T22:45:37+00:00";
        message = ''
          A new module is available: 'programs.jetbrains-remote'
        '';
      }

      {
        time = "2024-02-21T23:01:27+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'wayland.windowManager.river'.
        '';
      }

      {
        time = "2024-03-08T22:20:04+00:00";
        message = ''
          A new module is available: 'programs.zk'
        '';
      }

      {
        time = "2024-03-08T22:23:24+00:00";
        message = ''
          A new module is available: 'programs.ranger'.
        '';
      }

      {
        time = "2024-03-13T13:28:22+00:00";
        message = ''
          A new module is available: 'programs.joplin-desktop'.
        '';
      }

      {
        time = "2024-03-14T07:22:09+00:00";
        condition = config.services.gpg-agent.enable;
        message = ''
          'services.gpg-agent.pinentryFlavor' has been removed and replaced by
          'services.gpg-agent.pinentryPackage'.
        '';
      }

      {
        time = "2024-03-14T07:22:59+00:00";
        condition = config.programs.rbw.enable;
        message = ''
          'programs.rbw.pinentry' has been simplified to only accept 'null' or
          a package.
        '';
      }

      {
        time = "2024-03-15T08:39:52+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.activitywatch'.
        '';
      }

      {
        time = "2024-03-28T17:02:19+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.amberol'.
        '';
      }

      {
        time = "2024-04-08T21:43:38+00:00";
        message = ''
          A new module is available: 'programs.bun'.
        '';
      }

      {
        time = "2024-04-18T22:30:49+00:00";
        message = ''
          A new module is available: 'programs.fd'.
        '';
      }

      {
        time = "2024-04-19T09:23:52+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'programs.tofi'.
        '';
      }

      {
        time = "2024-04-19T10:01:55+00:00";
        message = ''
          A new module is available: 'programs.spotify-player'.
        '';
      }

      {
        time = "2024-04-19T14:53:17+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.remmina'.
        '';
      }

      {
        time = "2024-04-21T20:53:09+00:00";
        message = ''
          A new module is available: 'programs.poetry'.

          Poetry is a tool that helps you manage Python project dependencies and
          packages. See https://python-poetry.org/ for more.
        '';
      }

      {
        time = "2024-04-22T18:04:47+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.amberol'.

          Amberol is a music player with no delusions of grandeur. If you just
          want to play music available on your local system then Amberol is the
          music player you are looking for. See https://apps.gnome.org/Amberol/
          for more.
        '';
      }

      {
        time = "2024-04-28T20:27:08+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.psd'.

          Profile-sync-daemon (psd) is a tiny pseudo-daemon designed to manage
          your browser's profile in tmpfs and to periodically sync it back to
          your physical disc (HDD/SSD).
        '';
      }

      {
        time = "2024-04-29T22:01:51+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.swaync'.

          SwayNotificationCenter is a simple notification daemon with a GTK GUI
          for notifications and the control center. See
          https://github.com/ErikReider/SwayNotificationCenter for more.
        '';
      }

      {
        time = "2024-04-30T18:28:28+00:00";
        message = ''
          A new module is available: 'programs.freetube'.

          FreeTube is a YouTube client built around using YouTube more
          privately. You can enjoy your favorite content and creators without
          your habits being tracked. See https://freetubeapp.io/ for more.
        '';
      }

      {
        time = "2024-04-30T21:57:23+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.conky'.

          Conky is a system monitor for X. Conky can display just about
          anything, either on your root desktop or in its own window. See
          https://conky.cc/ for more.
        '';
      }

      {
        time = "2024-05-05T07:22:01+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.hypridle'.

          Hypridle is a program that monitors user activity and runs commands
          when idle or active. See https://github.com/hyprwm/hypridle for more.
        '';
      }

      {
        time = "2024-05-06T07:36:13+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'programs.gnome-shell'.

          GNOME Shell is the graphical shell of the GNOME desktop environment.
          It provides basic functions like launching applications and switching
          between windows, and is also a widget engine.
        '';
      }

      {
        time = "2024-05-10T10:30:58+00:00";
        message = ''
          A new module is available: 'programs.fastfetch'.

          Fastfetch is a Neofetch-like tool for fetching system information and
          displaying them in a pretty way. See
          https://github.com/fastfetch-cli/fastfetch for more.
        '';
      }

      {
        time = "2024-05-10T11:48:34+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'programs.hyprlock'.

          Hyprland's simple, yet multi-threaded and GPU-accelerated screen
          locking utility. See https://github.com/hyprwm/hyprlock for more.
        '';
      }

      {
        time = "2024-05-10T13:35:19+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.hyprpaper'.

          Hyprpaper is a blazing fast wallpaper utility for Hyprland with the
          ability to dynamically change wallpapers through sockets. It will work
          on all wlroots-based compositors, though. See
          https://github.com/hyprwm/hyprpaper for more.
        '';
      }

      {
        time = "2024-05-10T21:28:38+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'programs.yambar'.

          Yambar is a lightweight and configurable status panel for X11 and
          Wayland, that goes to great lengths to be both CPU and battery
          efficient - polling is only done when absolutely necessary.

          See https://codeberg.org/dnkl/yambar for more.
        '';
      }

      {
        time = "2024-05-25T14:36:03+00:00";
        message = ''
          Multiple new options are available:

          - 'nix.nixPath'
          - 'nix.keepOldNixPath'
          - 'nix.channels'
        '';
      }

      {
        time = "2024-06-22T05:49:48+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.blanket'.

          Blanket is a program you can use to improve your focus and increase
          your productivity by listening to different sounds. See
          https://github.com/rafaelmardojai/blanket for more.
        '';
      }

      {
        time = "2024-06-26T07:07:17+00:00";
        condition = with config.programs.yazi;
          enable && (enableBashIntegration || enableZshIntegration
            || enableFishIntegration || enableNushellIntegration);
        message = ''
          Yazi's shell integration wrappers have been renamed from 'ya' to 'yy'.

          A new option `programs.yazi.shellWrapperName` is also available that
          allows you to override this name.
        '';
      }

      {
        time = "2024-06-28T14:18:16+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.glance'.

          Glance is a self-hosted dashboard that puts all your feeds in
          one place. See https://github.com/glanceapp/glance for more.
        '';
      }

      {
        time = "2024-09-13T08:58:17+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.trayscale'.

          An unofficial GUI wrapper around the Tailscale CLI client.
        '';
      }

      {
        time = "2024-09-13T09:50:49+00:00";
        message = ''
          A new module is available: 'programs.neovide'.

          Neovide is a simple, no-nonsense, cross-platform graphical user
          interface for Neovim (an aggressively refactored and updated Vim
          editor).
        '';
      }

      {
        time = "2024-09-20T07:00:11+00:00";
        condition = config.programs.kitty.theme != null;
        message = ''
          The option 'programs.kitty.theme' has been deprecated, please use
          'programs.kitty.themeFile' instead.

          The 'programs.kitty.themeFile' option expects the file name of a
          theme from `kitty-themes`, without the `.conf` suffix. See
          <https://github.com/kovidgoyal/kitty-themes/tree/master/themes> for a
          list of themes.
        '';
      }

      {
        time = "2024-09-20T07:48:08+00:00";
        condition = hostPlatform.isLinux && config.services.swayidle.enable;
        message = ''
          The swayidle module behavior has changed. Specifically, swayidle was
          previously always called with a `-w` flag. This flag is now moved to
          the default `services.swayidle.extraArgs` value to make it optional.

          Your configuration may break if you already set this option and also
          rely on the flag being automatically added. To resolve this, please
          add `-w` to your assignment of `services.swayidle.extraArgs`.
        '';
      }

      {
        time = "2024-10-09T06:16:23+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.snixembed'.

          snixembed proxies StatusNotifierItems as XEmbedded systemtray-spec
          icons. This is useful for some tools in some environments, e.g., Safe
          Eyes in i3, lxde or mate.
        '';
      }

      {
        time = "2024-10-11T08:23:19+00:00";
        message = ''
          A new module is available: 'programs.vifm'.

          Vifm is a curses based Vim-like file manager extended with some useful
          ideas from mutt.
        '';
      }

      {
        time = "2024-10-17T13:07:55+00:00";
        message = ''
          A new module is available: 'programs.zed-editor'.

          Zed is a fast text editor for macOS and Linux.
          See https://zed.dev for more.
        '';
      }

      {
        time = "2024-10-18T14:01:07+00:00";
        message = ''
          A new module is available: 'programs.cmus'.

          cmus is a small, fast and powerful console music player.
        '';
      }

      {
        time = "2024-10-20T07:53:54+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'programs.nh'.

          nh is yet another Nix CLI helper. Adding functionality on top of the
          existing solutions, like nixos-rebuild, home-manager cli or nix
          itself.
        '';
      }

      {
        time = "2024-10-25T08:18:30+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'nixGL'.

          NixGL solve the "OpenGL" problem with nix. The 'nixGL' module provides
          integration of NixGL into Home Manager. See the "GPU on non-NixOS
          systems" section in the Home Manager manual for more.
        '';
      }

      {
        time = "2024-11-01T19:44:59+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.podman'.

          Podman is a daemonless container engine that lets you manage
          containers, pods, and images.

          This Home Manager module allows you to define containers that will run
          as systemd services.
        '';
      }

      {
        time = "2024-12-01T19:17:40+00:00";
        message = ''
          A new module is available: 'programs.nix-your-shell'.

          nix-your-shell is a wrapper for `nix develop` or `nix-shell` to retain
          the same shell inside the new environment.
        '';
      }

      {
        time = "2024-12-01T19:34:04+00:00";
        message = ''
          A new module is available: 'programs.kubecolor'.

          Kubecolor is a kubectl wrapper used to add colors to your kubectl
          output.
        '';
      }

      {
        time = "2024-12-04T20:00:00+00:00";
        condition = let
          sCfg = config.programs.starship;
          fCfg = config.programs.fish;
        in sCfg.enable && sCfg.enableFishIntegration && fCfg.enable;
        message = ''
          A new option 'programs.starship.enableInteractive' is available for
          the Fish shell that only enables starship if the shell is interactive.

          Some plugins require this to be set to 'false' to function correctly.
        '';
      }
      {
        time = "2024-12-08T17:22:13+00:00";
        condition = let
          usingMbsync = any (a: a.mbsync.enable)
            (attrValues config.accounts.email.accounts);
        in usingMbsync;
        message = ''
          isync/mbsync 1.5.0 has changed several things.

          isync gained support for using $XDG_CONFIG_HOME, and now places
          its config file in '$XDG_CONFIG_HOME/isyncrc'.

          isync changed the configuration options SSLType and SSLVersion to
          TLSType and TLSVersion respectively.

          All instances of
          'accounts.email.accounts.<account-name>.mbsync.extraConfig.account'
          that use 'SSLType' or 'SSLVersion' should be replaced with 'TLSType'
          or 'TLSVersion', respectively.

          TLSType options are unchanged.

          TLSVersions has a new syntax, requiring a change to the Nix syntax.
          Old Syntax: SSLVersions = [ "TLSv1.3" "TLSv1.2" ];
          New Syntax: TLSVersions = [ "+1.3" "+1.2" "-1.1" ];
          NOTE: The minus symbol means to NOT use that particular TLS version.
        '';
      }

      {
        time = "2024-12-10T22:20:10+00:00";
        condition = config.programs.nushell.enable;
        message = ''
          The module 'programs.nushell' can now manage the Nushell plugin
          registry with the option 'programs.nushell.plugins'.
        '';
      }

      {
        time = "2024-12-21T17:07:49+00:00";
        message = ''
          A new module is available: 'programs.pay-respects'.

          Pay Respects is a shell command suggestions tool and command-not-found
          and thefuck replacement written in Rust.
        '';
      }

      {
        time = "2024-12-22T08:24:29+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'programs.cavalier'.

          Cavalier is a GUI wrapper around the Cava audio visualizer.
        '';
      }

      {
        time = "2025-01-01T15:31:15+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          The 'systemd.user.startServices' option now defaults to 'true',
          meaning that services will automatically be restarted as needed when
          activating a configuration.

          Further, the "legacy" alternative has been removed and will now result
          in an evaluation error if used.

          The "suggest" alternative will remain for a while longer but may also
          be deprecated for removal in the future.
        '';
      }

      {
        time = "2025-01-01T23:16:35+00:00";
        message = ''
          A new module is available: 'programs.ghostty'.

          Ghostty is a terminal emulator that differentiates itself by being
          fast, feature-rich, and native. While there are many excellent
          terminal emulators available, they all force you to choose between
          speed, features, or native UIs. Ghostty provides all three.
        '';
      }
      {
        time = "2025-01-04T15:00:00+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'wayland.windowManager.wayfire'.

          Wayfire is a 3D Wayland compositor, inspired by Compiz and based on
          wlroots. It aims to create a customizable, extendable and lightweight
          environment without sacrificing its appearance.

          This Home Manager module allows you to configure both wayfire itself,
          as well as wf-shell.
        '';
      }

      {
        time = "2025-01-21T17:28:13+00:00";
        condition = with config.programs.yazi; enable && enableFishIntegration;
        message = ''
          Yazi's fish shell integration wrapper now calls the 'yazi' executable
          directly, ignoring any shell aliases with the same name.

          Your configuration may break if you rely on the wrapper calling a
          'yazi' alias.
        '';
      }
    ];
  };
}

