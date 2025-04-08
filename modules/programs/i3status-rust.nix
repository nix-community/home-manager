{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) literalExpression mkOption types;

  cfg = config.programs.i3status-rust;

  settingsFormat = pkgs.formats.toml { };

in
{
  meta.maintainers = with lib.maintainers; [
    farlion
    thiagokokada
  ];

  options.programs.i3status-rust = {
    enable = lib.mkEnableOption "a replacement for i3-status written in Rust";

    bars = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {

            blocks = mkOption {
              type = settingsFormat.type;
              default = [
                { block = "cpu"; }
                {
                  block = "disk_space";
                  path = "/";
                  info_type = "available";
                  interval = 20;
                  warning = 20.0;
                  alert = 10.0;
                  format = " $icon root: $available.eng(w:2) ";
                }
                {
                  block = "memory";
                  format = " $icon $mem_total_used_percents.eng(w:2) ";
                  format_alt = " $icon_swap $swap_used_percents.eng(w:2) ";
                }
                {
                  block = "sound";
                  click = [
                    {
                      button = "left";
                      cmd = "pavucontrol";
                    }
                  ];
                }
                {
                  block = "time";
                  interval = 5;
                  format = " $timestamp.datetime(f:'%a %d/%m %R') ";
                }
              ];
              description = ''
                Configuration blocks to add to i3status-rust
                {file}`config`. See
                <https://github.com/greshake/i3status-rust/blob/master/blocks.md>
                for block options.
              '';
              example = literalExpression ''
                [
                  {
                    block = "disk_space";
                    path = "/";
                    info_type = "available";
                    interval = 60;
                    warning = 20.0;
                    alert = 10.0;
                  }
                  {
                    block = "sound";
                    format = " $icon $output_name {$volume.eng(w:2) |}";
                    click = [
                      {
                        button = "left";
                        cmd = "pavucontrol --tab=3";
                      }
                    ];
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
                {file}`config`.
              '';
              example = literalExpression ''
                {
                  theme =  {
                    theme = "solarized-dark";
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
                <https://github.com/greshake/i3status-rust/blob/master/doc/themes.md>
                for a list of available icon sets.
              '';
              example = "awesome6";
            };

            theme = mkOption {
              type = types.str;
              default = "plain";
              description = ''
                The theme to use. See
                <https://github.com/greshake/i3status-rust/blob/master/doc/themes.md>
                for a list of available themes.
              '';
              example = "gruvbox-dark";
            };
          };
        }
      );

      default = {
        default = {
          blocks = [
            {
              block = "disk_space";
              path = "/";
              info_type = "available";
              interval = 60;
              warning = 20.0;
              alert = 10.0;
            }
            {
              block = "memory";
              format = " $icon mem_used_percents ";
              format_alt = " $icon $swap_used_percents ";
            }
            {
              block = "cpu";
              interval = 1;
            }
            {
              block = "load";
              interval = 1;
              format = " $icon $1m ";
            }
            { block = "sound"; }
            {
              block = "time";
              interval = 60;
              format = " $timestamp.datetime(f:'%a %d/%m %R') ";
            }
          ];
        };
      };
      description = ''
        Attribute set of i3status-rust bars, each with their own configuration.
        Each bar {var}`name` generates a config file suffixed with
        the bar's {var}`name` from the attribute set, like so:
        {file}`config-''${name}.toml`.

        This way, multiple config files can be generated, such as for having a
        top and a bottom bar.

        See
        {manpage}`i3status-rust(1)`
        for options.
      '';
      example = literalExpression ''
        bottom = {
          blocks = [
            {
               block = "disk_space";
               path = "/";
               info_type = "available";
               interval = 60;
               warning = 20.0;
               alert = 10.0;
             }
             {
               block = "memory";
               format_mem = " $icon $mem_used_percents ";
               format_swap = " $icon $swap_used_percents ";
             }
             {
               block = "cpu";
               interval = 1;
             }
             {
               block = "load";
               interval = 1;
               format = " $icon $1m ";
             }
             { block = "sound"; }
             {
               block = "time";
               interval = 60;
               format = " $timestamp.datetime(f:'%a %d/%m %R') ";
             }
          ];
          settings = {
            theme =  {
              theme = "solarized-dark";
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

    package = lib.mkPackageOption pkgs "i3status-rust" { };

  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.i3status-rust" pkgs lib.platforms.linux)
      {
        assertion =
          lib.versionOlder cfg.package.version "0.31.0" || lib.versionAtLeast cfg.package.version "0.31.2";
        message = "Only i3status-rust <0.31.0 or ≥0.31.2 is supported due to a config format incompatibility.";
      }
    ];

    home.packages = [ cfg.package ];

    xdg.configFile = lib.mapAttrs' (
      cfgFileSuffix: cfgBar:
      lib.nameValuePair "i3status-rust/config-${cfgFileSuffix}.toml" {
        onChange = ''
          ${pkgs.procps}/bin/pkill -u $USER -USR2 i3status-rs || true
        '';

        source = settingsFormat.generate "config-${cfgFileSuffix}.toml" (
          {
            theme =
              if lib.versionAtLeast cfg.package.version "0.30.0" then
                {
                  theme = cfgBar.theme;
                }
              else
                cfgBar.theme;
            icons =
              if lib.versionAtLeast cfg.package.version "0.30.0" then
                {
                  icons = cfgBar.icons;
                }
              else
                cfgBar.icons;
            block = cfgBar.blocks;
          }
          // cfgBar.settings
        );
      }
    ) cfg.bars;
  };
}
