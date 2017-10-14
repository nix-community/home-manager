{ config, lib, options, pkgs, ... }:

with lib;

let

  cfg = config.news;

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
        time = "2017-09-30T09:44:18+00:00";
        condition = with config.programs.vim;
          enable && (tabSize != null || lineNumbers != null);
        message = ''
          The options 'programs.vim.tabSize' and 'programs.vim.lineNumbers' have
          been deprecated and will be removed in the near future.

          The new and preferred way to configure tab size and line numbers is to
          use the more general 'programs.vim.settings' option. Specifically,
          instead of

          - 'programs.vim.lineNumbers' use 'programs.vim.settings.number', and

          - 'programs.vim.tabSize' use 'programs.vim.settings.tabstop' and
            'programs.vim.settings.shiftwidth'.
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
        time = "2018-01-08T20:39:56+00:00";
        condition = config.home.sessionVariableSetter != null;
        message =
          let
            opts = {
              bash = ''
                Instead the 'programs.bash' module will, when enabled,
                automatically set session variables. You can safely
                remove the 'home.sessionVariableSetter' option from your
                configuration.
              '';

              zsh = ''
                Instead the 'programs.zsh' module will, when enabled,
                automatically set session variables. You can safely
                remove the 'home.sessionVariableSetter' option from your
                configuration.
              '';

              pam = ''
                Unfortunately setting general session variables using
                PAM will not be directly supported after this date. The
                primary reason for this change is its limited support
                for variable expansion.

                To continue setting session variables from the Home
                Manager configuration you must either use the
                'programs.bash' or 'programs.zsh' modules or manually
                source the session variable file

                    $HOME/.nix-profile/etc/profile.d/hm-session-vars.sh

                within your shell configuration, see the README file for
                more information. This file requires a Bourne-like shell
                such as Bash or Z shell but hopefully other shells
                will be supported in the future.

                If you specifically need to set a session variable using
                PAM then the new option 'pam.sessionVariables' can be
                used. It works much the same as 'home.sessionVariables'
                but its attribute values must be valid within the PAM
                environment file.
              '';
            };
          in
            ''
              The 'home.sessionVariableSetter' option is now deprecated
              and will be removed on February 8, 2018.

              ${opts.${config.home.sessionVariableSetter}}
            '';
      }

      {
        time = "2018-01-25T11:35:08+00:00";
        condition = options.services.qsyncthingtray.enable.isDefined;
        message = ''
          'services.qsyncthingtray' has been merged into 'services.syncthing'.
          Please, use 'services.syncthing.tray' option to activate the tray service.

          The old module will be removed on February 25, 2018.
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
    ];
  };
}
