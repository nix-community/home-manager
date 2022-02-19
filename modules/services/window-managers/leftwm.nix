{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.xsession.windowManager.leftwm;
  tomlFormat = pkgs.formats.toml { };

  themeSubmodule = types.submodule {
    options = {
      up = mkOption {
        type = types.lines;
        default = "";
        example = ''
          #!/usr/bin/env bash

          leftwm command "LoadTheme $HOME/.config/leftwm/themes/current/theme.toml"
        '';
        description = ''
          Script for starting a theme.
          Should start theme specific programs and load <code>theme.toml</code>.
        '';
      };

      down = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Script for stoping a theme.
          Should restore LeftWM to an un-themed state.
        '';
        example = ''
          #!/usr/bin/env bash

          leftwm command "UnloadTheme"
        '';
      };

      theme = mkOption {
        type = tomlFormat.type;
        default = { };
        description = ''
          See 
          <link xlink:href="https://github.com/leftwm/leftwm/wiki/Theme-Config">https://github.com/leftwm/leftwm/wiki/Theme-Config</link>
          for available options.
        '';
        example = literalExpression ''
          {
            margin = 5;
            border_width = 10;
            default_border_color = "#37474F";
            floating_border_color = "#225588";
            focused_border_color = "#885522";
          }
        '';
      };
    };
  };
in {
  meta.maintainers = [ maintainers.autumnal ];

  options = {
    xsession.windowManager.leftwm = {
      enable = mkEnableOption "leftwm window manager";

      package = mkOption {
        type = types.package;
        default = pkgs.leftwm;
        defaultText = literalExpression "pkgs.leftwm";
        description = ''
          LeftWM package to use.
          </para>
          <para>
          The <link xlink:href="https://github.com/leftwm/leftwm/">LeftWM GitHub Repo</link> is a flake and can be used directly.
        '';
      };

      settings = mkOption {
        type = tomlFormat.type;
        default = { };
        example = literalExpression ''
          {
            modkey = "Mod4";
            keybind = [
              {
                command = "Execute";
                value = "${pkgs.alacritty}/bin/alacritty";
                modifier = ["modkey" "Shift"];
                key = "Return";
              }
            ];
          }
        '';
        description = ''
          LeftWM settings.
          </para>
          <para>
          See <link xlink:href="https://github.com/leftwm/leftwm/wiki/Config"/>.
          Nix config is almost equivalent to "short syntax" shown in <link xlink:href="https://github.com/leftwm/leftwm/wiki/Config">LeftWM Wiki</link>.
        '';
      };

      themes = mkOption {
        type = types.attrsOf themeSubmodule;
        default = { };
        description = ''
          Theme configuration.
          The keys of the attributes are the name of the theme.
          </para>
          <para>
          <varname>"current"</varname> is the default theme used by LeftWM. 
          Symlinking themes to <code>$HOME/.config/leftwm/themes/current</code> instead is recommended by LeftWM.
        '';
        example = literalExpression ''
          {
            "current" = { ... }
            "nord" = { ... }
            "onehalf" = { ... }
          }
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "xsession.windowManager.leftwm" pkgs
        platforms.linux)
    ];

    xdg.configFile = mkMerge ([
      # LeftWM Config
      ({
        "leftwm/config.toml" = mkIf (cfg.settings != { }) {
          source = tomlFormat.generate "leftwm-config" cfg.settings;
        };
      })
      # Themes
      (listToAttrs (flatten (mapAttrsToList (name: theme: [
        {
          name = "leftwm/themes/${name}/up";
          value = {
            text = theme.up;
            executable = true;
          };
        }
        {
          name = "leftwm/themes/${name}/down";
          value = {
            text = theme.down;
            executable = true;
          };
        }
        {
          name = "leftwm/themes/${name}/theme.toml";
          value.source = tomlFormat.generate "theme-${name}-config" theme.theme;
        }
      ]) cfg.themes)))
    ]);

    home.packages = [ cfg.package ];

    xsession.windowManager.command = "${cfg.package}/bin/leftwm";
  };
}
