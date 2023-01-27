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

    config = {
      id = mkDefault (builtins.hashString "sha256" config.message);
    };
  });

in

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    news = {
      display = mkOption {
        type = types.enum [ "silent" "notify" "show" ];
        default = "notify";
        description = ''
          How unread and relevant news should be presented when
          running <command>home-manager build</command> and
          <command>home-manager switch</command>.

          </para><para>

          The options are

          <variablelist>
          <varlistentry>
            <term><literal>silent</literal></term>
            <listitem>
              <para>
                Do not print anything during build or switch. The
                <command>home-manager news</command> command still
                works for viewing the entries.
              </para>
            </listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>notify</literal></term>
            <listitem>
              <para>
                The number of unread and relevant news entries will be
                printed to standard output. The <command>home-manager
                news</command> command can later be used to view the
                entries.
              </para>
            </listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>show</literal></term>
            <listitem>
              <para>
                A pager showing unread news entries is opened.
              </para>
            </listitem>
          </varlistentry>
          </variablelist>
        '';
      };

      entries = mkOption {
        internal = true;
        type = types.listOf entryModule;
        default = [];
        description = "News entries.";
      };
    };
  };

  config = {
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
        condition = hostPlatform.isLinux && config.services.screen-locker.enable;
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
    ];
  };
}
