{ config, lib, pkgs, ... }:

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
        time = "2017-09-28T21:39:45+00:00";
        condition =
          config.xsession.enable
          && config.xsession.windowManager.usesDeprecated;
        message = ''
          The 'xsession.windowManager' option is now deprecated,
          please use 'xsession.windowManager.command' instead.

          This change was made to prepare for window manager modules
          under the 'xsession.windowManager' namespace. For example,
          'xsession.windowManager.xmonad' and
          'xsession.windowManager.i3'.
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
        time = "2017-10-19T09:33:10+00:00";
        condition =
          config.xsession.enable
          && config.xsession.windowManager.usesDeprecated;
        message = ''
          The 'xsession.windowManager' option is deprecated and will
          be removed on October 31, 2017. To avoid evaluation errors
          you must change to using 'xsession.windowManager.command'
          before that date.
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
        time = "2017-10-23T22:54:33+00:00";
        condition = config.programs.home-manager.modulesPath != null;
        message = ''
          The 'programs.home-manager.modulesPath' option is now
          deprecated and will be removed on November 24, 2017. Please
          use the option 'programs.home-manager.path' instead.
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
    ];
  };
}
