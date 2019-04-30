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
    news.entries = [
      {
        time = "2017-09-01T10:56:28+00:00";
        message = ''
          Hello! This is a news entry and it represents an
          experimental new feature of Home Manager. The idea is to
          inform you when something of importance happens in Home
          Manager or its modules.

          We will try to not disturb you about the same news more than
          once so the next time you run

              home-manager switch

          or

              home-manager build

          it should not notify you about this text again.

          News items may be conditional and will then only show if the
          condition holds, for example if they are relevant to your
          configuration.

          If you want to see all relevant news then please use the

              home-manager news

          command.

          Since this is an experimental feature any positive or
          negative feedback would be greatly appreciated. For example,
          by commenting in https://git.io/v5BJL.
        '';
      }

      {
        time = "2017-09-10T22:15:19+00:00";
        condition = config.programs.zsh.enable;
        message = ''
          Home Manager now offers its own minimal zsh plugin manager
          under the 'programs.zsh.plugins' option path. By statically
          sourcing your plugins it achieves no startup overhead.
        '';
      }

      {
        time = "2017-09-12T13:11:48+00:00";
        condition = (
          config.programs.zsh.enable &&
          config.programs.zsh.shellAliases != {}
        );
        message = ''
          Aliases defined in 'programs.zsh.shellAliases'
          are now have the highest priority. Such aliases will
          not be redefined by the code in 'programs.zsh.initExtra'
          or any external plugins.
        '';
      }

      {
        time = "2017-09-12T14:22:18+00:00";
        message = ''
          A new service is available: 'services.blueman-applet'.
        '';
      }

      {
        time = "2017-09-13T11:30:22+00:00";
        message = ''
          A new service is available: 'services.compton'.
        '';
      }

      {
        time = "2017-09-20T14:47:14+00:00";
        message = ''
          A new service is available: 'services.screen-locker'.
        '';
      }

      {
        time = "2017-09-22T12:09:01+00:00";
        condition = isString config.programs.git.extraConfig;
        message = ''
          The 'programs.git.extraConfig' parameter now accepts
          attributes instead of strings which allows more flexible
          configuration.

          The string parameter type will be deprecated in the future,
          please change your configuration file accordingly.

          For example, if your configuration includes

              programs.git.extraConfig = '''
                [core]
                editor = vim
              ''';

          then you can now change it to

              programs.git.extraConfig = {
                core = {
                  editor = "vim";
                };
              };
        '';
      }

      {
        time = "2017-09-27T07:28:54+00:00";
        message = ''
          A new program module is available: 'programs.command-not-found'.

          Note, this differs from the NixOS system command-not-found
          tool in that NIX_AUTO_INSTALL is not supported.
        '';
      }

      {
        time = "2017-09-28T12:39:36+00:00";
        message = ''
          A new program module is available: 'programs.rofi';
        '';
      }

      {
        time = "2017-10-02T11:15:03+00:00";
        condition = config.services.udiskie.enable;
        message = ''
          The udiskie service now defaults to automatically mounting
          new devices. Previous behavior was to not automatically
          mount. To restore this previous behavior add

              services.udiskie.automount = false;

          to your Home Manager configuration.
        '';
      }

      {
        time = "2017-10-04T18:36:07+00:00";
        message = ''
          A new module is available: 'xsession.windowManager.xmonad'.
        '';
      }

      {
        time = "2017-10-06T08:21:43+00:00";
        message = ''
          A new service is available: 'services.polybar'.
        '';
      }

      {
        time = "2017-10-09T16:38:34+00:00";
        message = ''
          A new module is available: 'fonts.fontconfig'.

          In particular, the Boolean option

              fonts.fontconfig.enableProfileFonts

          was added for those who do not use NixOS and want to install
          font packages using 'nix-env' or 'home.packages'. If you are
          using NixOS then you do not need to enable this option.
        '';
      }

      {
        time = "2017-10-12T11:21:45+00:00";
        condition = config.programs.zsh.enable;
        message = ''
          A new option in zsh module is available: 'programs.zsh.sessionVariables'.

          This option can be used to set zsh specific session variables which
          will be set only on zsh launch.
        '';
      }

      {
        time = "2017-10-15T13:59:47+00:00";
        message = ''
          A new module is available: 'programs.man'.

          This module is enabled by default and makes sure that manual
          pages are installed for packages in 'home.packages'.
        '';
      }

      {
        time = "2017-10-20T12:15:27+00:00";
        condition = with config.systemd.user;
          services != {} || sockets != {} || targets != {} || timers != {};
        message = ''
          Home Manager's interaction with systemd is now done using
          'systemctl' from Nixpkgs, not the 'systemctl' in '$PATH'.

          If you are using a distribution whose systemd is
          incompatible with the version in Nixpkgs then you can
          override this behavior by adding

              systemd.user.systemctlPath = "/usr/bin/systemctl"

          to your configuration. Home Manager will then use your
          chosen version.
        '';
      }

      {
        time = "2017-10-23T23:10:29+00:00";
        condition = !config.programs.home-manager.enable;
        message = ''
          Unfortunately, due to some internal restructuring it is no
          longer possible to install the home-manager command when
          having

              home-manager = import ./home-manager { inherit pkgs; };

          in the '~/.config/nixpkgs/config.nix' package override
          section. Attempting to use the above override will now
          result in the error "cannot coerce a set to a string".

          To resolve this please delete the override from the
          'config.nix' file and either link the Home Manager overlay

              $ ln -s ~/.config/nixpkgs/home-manager/overlay.nix \
                      ~/.config/nixpkgs/overlays/home-manager.nix

          or add

              programs.home-manager.enable = true;

          to your Home Manager configuration. The latter is
          recommended as the home-manager tool then is updated
          automatically whenever you do a switch.
        '';
      }

      {
        time = "2017-10-23T23:26:17+00:00";
        message = ''
          A new module is available: 'nixpkgs'.

          Like the identically named NixOS module, this allows you to
          set Nixpkgs options and define Nixpkgs overlays. Note, the
          changes you make here will not automatically apply to Nix
          commands run outside Home Manager.
        '';
      }

      {
        time = "2017-10-28T23:39:55+00:00";
        message = ''
          A new module is available: 'xdg'.

          If enabled, this module allows configuration of the XDG base
          directory paths.

          Whether the module is enabled or not, it also offers the
          option 'xdg.configFile', which acts much like 'home.file'
          except the target path is relative to the XDG configuration
          directory. That is, unless `XDG_CONFIG_HOME` is configured
          otherwise, the assignment

              xdg.configFile.hello.text = "hello world";

          will result in a file '$HOME/.config/hello'.

          Most modules in Home Manager that previously were hard coded
          to write configuration to '$HOME/.config' now use this
          option and will therefore honor the XDG configuration
          directory.
        '';
      }

      {
        time = "2017-10-31T11:46:07+00:00";
        message = ''
          A new window manager module is available: 'xsession.windowManager.i3'.
        '';
      }

      {
        time = "2017-11-12T00:18:59+00:00";
        message = ''
          A new program module is available: 'programs.neovim'.
        '';
      }

      {
        time = "2017-11-14T19:56:49+00:00";
        condition = with config.xsession.windowManager; (
          i3.enable && i3.config != null && i3.config.startup != []
        );
        message = ''
          A new 'notification' option was added to
          xsession.windowManager.i3.startup submodule.

          Startup commands are now executed with the startup-notification
          support enabled by default. Please, set 'notification' to false
          where --no-startup-id option is necessary.
        '';
      }

      {
        time = "2017-11-17T10:36:10+00:00";
        condition = config.xsession.windowManager.i3.enable;
        message = ''
          The i3 window manager module has been extended with the following options:

            i3.config.keycodebindings
            i3.config.window.commands
            i3.config.window.hideEdgeBorders
            i3.config.focus.mouseWarping
        '';
      }

      {
        time = "2017-11-26T21:57:23+00:00";
        message = ''
          Two new modules are available:

              'services.kbfs' and 'services.keybase'
        '';
      }

      {
        time = "2017-12-07T22:23:11+00:00";
        message = ''
          A new module is available: 'services.parcellite'
        '';
      }

      {
        time = "2017-12-11T17:23:12+00:00";
        condition = config.home.activation ? reloadSystemD;
        message = ''
          The Boolean option 'systemd.user.startServices' is now
          available. When enabled the current naive systemd unit
          reload logic is replaced by a more sophisticated one that
          attempts to automatically start, stop, and restart units as
          necessary.
        '';
      }

      {
        time = "2018-02-02T11:15:00+00:00";
        message = ''
          A new program configuration is available: 'programs.mercurial'
        '';
      }

      {
        time = "2018-02-03T10:00:00+00:00";
        message = ''
          A new module is available: 'services.stalonetray'
        '';
      }

      {
        time = "2018-02-04T22:58:49+00:00";
        condition = config.xsession.enable;
        message = ''
          A new option 'xsession.pointerCursor' is now available. It
          allows specifying the pointer cursor theme and size. The
          settings will be applied in the xsession, Xresources, and
          GTK configurations.
        '';
      }

      {
        time = "2018-02-06T20:23:34+00:00";
        message = ''
          It is now possible to use Home Manager as a NixOS module.
          This allows you to prepare user environments from the system
          configuration file, which often is more convenient than
          using the 'home-manager' tool. It also opens up additional
          possibilities, for example, to automatically configure user
          environments in NixOS declarative containers or on systems
          deployed through NixOps.

          This feature should be considered experimental for now and
          some critial limitations apply. For example, it is currently
          not possible to use 'nixos-rebuild build-vm' when using the
          Home Manager NixOS module. That said, it should be
          reasonably robust and stable for simpler use cases.

          To make Home Manager available in your NixOS system
          configuration you can add

              imports = [
                "''${builtins.fetchTarball https://github.com/rycee/home-manager/archive/master.tar.gz}/nixos"
              ];

          to your 'configuration.nix' file. This will introduce a new
          NixOS option called 'home-manager.users' whose type is an
          attribute set mapping user names to Home Manager
          configurations.

          For example, a NixOS configuration may include the lines

              users.users.eve.isNormalUser = true;
              home-manager.users.eve = {
                home.packages = [ pkgs.atool pkgs.httpie ];
                programs.bash.enable = true;
              };

          and after a 'nixos-rebuild switch' the user eve's
          environment should include a basic Bash configuration and
          the packages atool and httpie.

          More detailed documentation on the intricacies of this new
          feature is slowly forthcoming.
        '';
      }

      {
        time = "2018-02-09T21:14:42+00:00";
        condition = with config.programs.rofi; enable && colors != null;
        message = ''
          The new and preferred way to configure the rofi theme is
          using rasi themes through the 'programs.rofi.theme' option.
          This option can take as value either the name of a
          pre-installed theme or the path to a theme file.

          A rasi theme can be generated from an Xresources config
          using 'rofi -dump-theme'.

          The option 'programs.rofi.colors' is still supported but may
          become deprecated and removed in the future.
        '';
      }

      {
        time = "2018-02-19T21:45:26+00:00";
        message = ''
          A new module is available: 'programs.pidgin'
        '';
      }

      {
        time = "2018-03-04T06:54:26+00:00";
        message = ''
          A new module is available: 'services.unclutter'
        '';
      }

      {
        time = "2018-03-07T21:38:27+00:00";
        message = ''
          A new module is available: 'programs.fzf'.
        '';
      }

      {
        time = "2018-03-25T06:49:57+00:00";
        condition = with config.programs.ssh; enable && matchBlocks != {};
        message = ''
          Options set through the 'programs.ssh' module are now placed
          at the end of the SSH configuration file. This was done to
          make it possible to override global options such as
          'ForwardAgent' or 'Compression' inside a host match block.

          If you truly need to override an SSH option across all match
          blocks then the new option

              programs.ssh.extraOptionOverrides

          can be used.
        '';
      }

      {
        time = "2018-04-19T07:42:01+00:00";
        message = ''
          A new module is available: 'programs.autorandr'.
        '';
      }

      {
        time = "2018-04-19T15:44:55+00:00";
        condition = config.programs.git.enable;
        message = ''
          A new option 'programs.git.includes' is available. Additional
          Git configuration files may be included via

              programs.git.includes = [
                { path = "~/path/to/config.inc"; }
              ];

          or conditionally via

              programs.git.includes = [
                { path = "~/path/to/config.inc"; condition = "gitdir:~/src/"; }
              ];

          and the corresponding '[include]' or '[includeIf]' sections will be
          appended to the main Git configuration file.
        '';
      }

      {
        time = "2018-05-01T20:49:31+00:00";
        message = ''
          A new module is available: 'services.mbsync'.
        '';
      }
      {
        time = "2018-05-03T12:34:47+00:00";
        message = ''
          A new module is available: 'services.flameshot'.
        '';
      }

      {
        time = "2018-05-18T18:34:15+00:00";
        message = ''
          A new module is available: 'qt'

          At the moment this module allows you to set up Qt to use the
          GTK+ theme, and not much else.
        '';
      }

      {
        time = "2018-06-05T01:36:45+00:00";
        message = ''
          A new module is available: 'services.kdeconnect'.
        '';
      }

      {
        time = "2018-06-09T09:11:59+00:00";
        message = ''
          A new module is available: `programs.newsboat`.
        '';
      }

      {
        time = "2018-07-01T14:33:15+00:00";
        message = ''
          A new module is available: 'accounts.email'.

          As the name suggests, this new module offers a number of
          options for configuring email accounts. This, for example,
          includes the email address and owner's real name but also
          server settings for IMAP and SMTP.

          The intent is to have a central location for account
          specific configuration that other modules can use.

          Note, this module is still somewhat experimental and its
          structure should not be seen as final. Feedback is greatly
          appreciated, both positive and negative.
        '';
      }

      {
        time = "2018-07-01T16:07:04+00:00";
        message = ''
          A new module is available: 'programs.mbsync'.
        '';
      }

      {
        time = "2018-07-01T16:12:20+00:00";
        message = ''
          A new module is available: 'programs.notmuch'.
        '';
      }

      {
        time = "2018-07-07T15:48:56+00:00";
        message = ''
          A new module is available: 'xsession.windowManager.awesome'.
        '';
      }

      {
        time = "2018-07-18T20:14:11+00:00";
        message = ''
          A new module is available: 'services.mpd'.
        '';
      }

      {
        time = "2018-07-31T13:33:39+00:00";
        message = ''
          A new module is available: 'services.status-notifier-watcher'.
        '';
      }

      {
        time = "2018-07-31T13:47:06+00:00";
        message = ''
          A new module is available: 'programs.direnv'.
        '';
      }

      {
        time = "2018-08-17T20:30:14+00:00";
        message = ''
          A new module is available: 'programs.fish'.
        '';
      }

      {
        time = "2018-08-18T19:03:42+00:00";
        condition = config.services.gpg-agent.enable;
        message = ''
          A new option is available: 'services.gpg-agent.extraConfig'.

          Extra lines may be appended to $HOME/.gnupg/gpg-agent.conf
          using this option.
        '';
      }

      {
        time = "2018-08-19T20:46:09+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new modules is available: 'programs.chromium'.
        '';
      }

      {
        time = "2018-08-20T20:27:26+00:00";
        message = ''
          A new module is available: 'programs.msmtp'.
        '';
      }

      {
        time = "2018-08-21T20:13:50+00:00";
        message = ''
          A new module is available: 'services.pasystray'.
        '';
      }

      {
        time = "2018-08-29T20:27:04+00:00";
        message = ''
          A new module is available: 'programs.offlineimap'.
        '';
      }

      {
        time = "2018-09-18T21:25:14+00:00";
        message = ''
          A new module is available: 'programs.taskwarrior'.
        '';
      }

      {
        time = "2018-09-18T21:43:54+00:00";
        message = ''
          A new module is available: 'programs.zathura'.
        '';
      }

      {
        time = "2018-09-20T19:26:40+00:00";
        message = ''
          A new module is available: 'programs.noti'.
        '';
      }

      {
        time = "2018-09-20T22:10:45+00:00";
        message = ''
          A new module is available: 'programs.go'.
        '';
      }

      {
        time = "2018-09-27T17:48:08+00:00";
        message = ''
          A new module is available: 'programs.obs-studio'.
        '';
      }

      {
        time = "2018-09-28T21:38:48+00:00";
        message = ''
          A new module is available: 'programs.alot'.
        '';
      }

      {
        time = "2018-10-20T09:30:57+00:00";
        message = ''
          A new module is available: 'programs.urxvt'.
        '';
      }

      {
        time = "2018-11-13T23:08:03+00:00";
        message = ''
          A new module is available: 'programs.tmux'.
        '';
      }

      {
        time = "2018-11-18T18:55:15+00:00";
        message = ''
          A new module is available: 'programs.astroid'.
        '';
      }

      {
        time = "2018-11-18T21:41:51+00:00";
        message = ''
          A new module is available: 'programs.afew'.
        '';
      }

      {
        time = "2018-11-19T00:40:34+00:00";
        message = ''
          A new nix-darwin module is available. Use it the same way the NixOS
          module is used. A major limitation is that Home Manager services don't
          work, as they depend explicitly on Linux and systemd user services.
          However, 'home.file' and 'home.packages' do work. Everything else is
          untested at this time.
        '';
      }

      {
        time = "2018-11-24T16:22:19+00:00";
        message = ''
          A new option 'home.stateVersion' is available. Its function
          is much like the 'system.stateVersion' option in NixOS.

          Briefly, the state version indicates a stable set of option
          defaults. In the future, whenever Home Manager changes an
          option default in a way that may cause program breakage it
          will do so only for the unstable state version, currently
          19.03. Once 19.03 becomes the stable version only backwards
          compatible changes will be made and 19.09 becomes the
          unstable state version.

          The default value for this option is 18.09 but it may still
          be a good idea to explicitly add

              home.stateVersion = "18.09";

          to your Home Manager configuration.
        '';
      }

      {
        time = "2018-11-25T22:10:15+00:00";
        message = ''
          A new module is available: 'services.nextcloud-client'.
        '';
      }

      {
        time = "2018-11-25T22:55:12+00:00";
        message = ''
          A new module is available: 'programs.vscode'.
        '';
      }

      {
        time = "2018-12-04T21:54:38+00:00";
        condition = config.programs.beets.settings != {};
        message = ''
          A new option 'programs.beets.enable' has been added.
          Starting with state version 19.03 this option defaults to
          false. For earlier versions it defaults to true if
          'programs.beets.settings' is non-empty.

          It is recommended to explicitly add

              programs.beets.enable = true;

          to your configuration.
        '';
      }

      {
        time = "2018-12-12T21:02:05+00:00";
        message = ''
          A new module is available: 'programs.jq'.
        '';
      }

      {
        time = "2018-12-24T16:26:16+00:00";
        message = ''
          A new module is available: 'dconf'.

          Note, on NixOS you may need to add

              services.dbus.packages = with pkgs; [ gnome3.dconf ];

          to the system configuration for this module to work as
          expected. In particular if you get the error message

              The name ca.desrt.dconf was not provided by any .service files

          when activating your Home Manager configuration.
        '';
      }

      {
        time = "2018-12-28T12:32:30+00:00";
        message = ''
          A new module is available: 'programs.opam'.
        '';
      }

      {
        time = "2019-01-18T00:21:56+00:00";
        message = ''
          A new module is available: 'programs.matplotlib'.
        '';
      }

      {
        time = "2019-01-26T13:20:37+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.xembed-sni-proxy'.
        '';
      }

      {
        time = "2019-01-28T23:36:10+00:00";
        message = ''
          A new module is available: 'programs.irssi'.
        '';
      }

      {
        time = "2019-02-09T14:09:58+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.emacs'.

          This module provides a user service that runs the Emacs
          configured in

              programs.emacs

          as an Emacs daemon.
        '';
      }

      {
        time = "2019-02-16T20:33:56+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          When using Home Manager as a NixOS submodule it is now
          possible to install packages using the NixOS

              users.users.<name?>.packages

          option. This is enabled by adding

              home-manager.useUserPackages = true;

          to your NixOS system configuration. This mode of operation
          is necessary if you want to use 'nixos-rebuild build-vm'.
        '';
      }

      {
        time = "2019-02-17T21:11:24+00:00";
        message = ''
          A new module is available: 'programs.keychain'.
        '';
      }

      {
        time = "2019-02-24T00:32:23+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new service is available: 'services.mpdris2'.
        '';
      }

      {
        time = "2019-03-19T22:56:20+00:00";
        message = ''
          A new module is available: 'programs.bat'.
        '';
      }

      {
        time = "2019-03-19T23:07:34+00:00";
        message = ''
          A new module is available: 'programs.lsd'.
        '';
      }

      {
        time = "2019-04-09T20:10:22+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.xcape'.
        '';
      }

      {
        time = "2019-04-11T22:50:10+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          The type used for the systemd unit options under

              systemd.user.services, systemd.user.sockets, etc.

          has been changed to offer more robust merging of configurations.

          If you don't override values within systemd units then you are not
          affected by this change. Unfortunately, if you do override unit values
          you may encounter errors due to this change.

          In particular, if you get an error saying that a "unique option" is
          "defined multiple times" then you need to use 'lib.mkForce'. For
          example,

              systemd.user.services.foo.Service.ExecStart = "/foo/bar";

          becomes

              systemd.user.services.foo.Service.ExecStart = lib.mkForce "/foo/bar";

          We had to make this change because the old merging was causing too
          many confusing situations for people. Apologies for potentially
          breaking your configuration!
        '';
      }

      {
        time = "2019-04-14T15:35:16+00:00";
        message = ''
          A new module is available: 'programs.skim'.
        '';
      }

      {
        time = "2019-04-22T12:43:20+00:00";
        message = ''
          A new module is available: 'programs.alacritty'.
        '';
      }

      {
        time = "2019-04-26T22:53:48+00:00";
        condition = config.programs.vscode.enable;
        message = ''
          A new module is available: 'programs.vscode.haskell'.

          Enable to add Haskell IDE Engine and syntax highlighting
          support to your VSCode.
        '';
      }

      {
        time = "2019-05-04T23:56:39+00:00";
        condition = hostPlatform.isLinux;
        message = ''
          A new module is available: 'services.rsibreak'.
        '';
      }

      {
        time = "2019-05-07T20:49:29+00:00";
        message = ''
          A new module is available: 'programs.mpv'.
        '';
      }
    ];
  };
}
