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
    ];
  };
}
