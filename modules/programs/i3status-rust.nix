{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.i3status-rust;

  settingsFormat = pkgs.formats.toml { };

in {
  meta.maintainers = [ maintainers.farlion ];

  options.programs.i3status-rust = {
    enable = mkEnableOption "a replacement for i3-status written in Rust";

    bars = mkOption {
      type = types.attrsOf (types.submodule {
        options = {

          blocks = mkOption {
            type = settingsFormat.type;
            default = [
              {
                block = "disk_space";
                path = "/";
                alias = "/";
                info_type = "available";
                unit = "GB";
                interval = 60;
                warning = 20.0;
                alert = 10.0;
              }
              {
                block = "memory";
                display_type = "memory";
                format_mem = "{mem_used_percents}";
                format_swap = "{swap_used_percents}";
              }
              {
                block = "cpu";
                interval = 1;
              }
              {
                block = "load";
                interval = 1;
                format = "{1m}";
              }
              { block = "sound"; }
              {
                block = "time";
                interval = 60;
                format = "%a %d/%m %R";
              }
            ];
            description = ''
              Configuration blocks to add to i3status-rust
              <filename>config</filename>. See
              <link xlink:href="https://github.com/greshake/i3status-rust/blob/master/blocks.md"/>
              for block options.
            '';
            example = literalExpression ''
              [
                {
                  block = "disk_space";
                  path = "/";
                  alias = "/";
                  info_type = "available";
                  unit = "GB";
                  interval = 60;
                  warning = 20.0;
                  alert = 10.0;
                }
                {
                  block = "sound";
                  format = "{output_name} {volume}%";
                  on_click = "pavucontrol --tab=3";
                  mappings = {
                   "alsa_output.pci-0000_00_1f.3.analog-stereo" = "";
                   "bluez_sink.70_26_05_DA_27_A4.a2dp_sink" = "";
                  };
                }
              ];
            '';
          };

          settings = mkOption {
            type = settingsFormat.type;
            default = { };
            description = ''
              Any extra options to add to i3status-rust
              <filename>config</filename>.
            '';
            example = literalExpression ''
              {
                theme =  {
                  name = "solarized-dark";
                  overrides = {
                    idle_bg = "#123456";
                    idle_fg = "#abcdef";
                  };
                };
              }
            '';
          };

          icons = mkOption {
            type = types.str;
            default = "none";
            description = ''
              The icons set to use. See
              <link xlink:href="https://github.com/greshake/i3status-rust/blob/master/themes.md"/>
              for a list of available icon sets.
            '';
            example = "awesome5";
          };

          theme = mkOption {
            type = types.str;
            default = "plain";
            description = ''
              The theme to use. See
              <link xlink:href="https://github.com/greshake/i3status-rust/blob/master/themes.md"/>
              for a list of available themes.
            '';
            example = "gruvbox-dark";
          };
        };
      });

      default = {
        default = {
          blocks = [
            {
              block = "disk_space";
              path = "/";
              alias = "/";
              info_type = "available";
              unit = "GB";
              interval = 60;
              warning = 20.0;
              alert = 10.0;
            }
            {
              block = "memory";
              display_type = "memory";
              format_mem = "{Mup}%";
              format_swap = "{SUp}%";
            }
            {
              block = "cpu";
              interval = 1;
            }
            {
              block = "load";
              interval = 1;
              format = "{1m}";
            }
            { block = "sound"; }
            {
              block = "time";
              interval = 60;
              format = "%a %d/%m %R";
            }
          ];
        };
      };
      description = ''
        Attribute set of i3status-rust bars, each with their own configuration.
        Each bar <varname>name</varname> generates a config file suffixed with
        the bar's <varname>name</varname> from the attribute set, like so:
        <filename>config-<replaceable>name</replaceable>.toml</filename>.
        </para><para>
        This way, multiple config files can be generated, such as for having a
        top and a bottom bar.
        </para><para>
        See
        <citerefentry>
         <refentrytitle>i3status-rust</refentrytitle>
         <manvolnum>1</manvolnum>
        </citerefentry>
        for options.
      '';
      example = literalExpression ''
        bottom = {
          blocks = [
            {
               block = "disk_space";
               path = "/";
               alias = "/";
               info_type = "available";
               unit = "GB";
               interval = 60;
               warning = 20.0;
               alert = 10.0;
             }
             {
               block = "memory";
               display_type = "memory";
               format_mem = "{mem_used_percents}";
               format_swap = "{swap_used_percents}";
             }
             {
               block = "cpu";
               interval = 1;
             }
             {
               block = "load";
               interval = 1;
               format = "{1m}";
             }
             { block = "sound"; }
             {
               block = "time";
               interval = 60;
               format = "%a %d/%m %R";
             }
          ];
          settings = {
            theme =  {
              name = "solarized-dark";
              overrides = {
                idle_bg = "#123456";
                idle_fg = "#abcdef";
              };
            };
          };
          icons = "awesome5";
          theme = "gruvbox-dark";
        };
      '';
    };

    package = mkOption {
      type = types.package;
      default = pkgs.i3status-rust;
      defaultText = literalExpression "pkgs.i3status-rust";
      description = "Package providing i3status-rust";
    };

  };

  config = mkIf cfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "programs.i3status-rust" pkgs
        platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile = mapAttrs' (cfgFileSuffix: cfg:
      nameValuePair ("i3status-rust/config-${cfgFileSuffix}.toml") ({
        onChange = mkIf config.xsession.windowManager.i3.enable ''
          i3Socket="''${XDG_RUNTIME_DIR:-/run/user/$UID}/i3/ipc-socket.*"
          if [[ -S $i3Socket ]]; then
            ${config.xsession.windowManager.i3.package}/bin/i3-msg -s $i3Socket restart >/dev/null
          fi
        '';

        source = settingsFormat.generate ("config-${cfgFileSuffix}.toml") ({
          theme = cfg.theme;
          icons = cfg.icons;
          block = cfg.blocks;
        } // cfg.settings);
      })) cfg.bars;
  };
}
