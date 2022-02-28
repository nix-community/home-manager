{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.xsession.windowManager.leftwm;
  tomlFormat = pkgs.formats.toml { };
in {
  meta.maintainers = [ hm.maintainers.autumnal ];

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
                value = "''${pkgs.alacritty}/bin/alacritty";
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
        type = types.attrsOf
          (types.either types.package (types.attrsOf types.package));
        default = { };
        description = ''
          Theme configuration.
          The keys of the attributes are the name of the theme.
          Subattributes are files of the theme. Currently 
          <varname>up</varname>,
          <varname>down</varname> and
          <varname>theme.toml</varname> are required by leftwm.
          <varname>up</varname> and <varname>down</varname> are expected to be executable.
          </para>
          <para>
          <varname>"current"</varname> is the default theme used by LeftWM.
        '';
        example = literalExpression ''
          {
            "current" = {
              up = pkgs.writeShellScript "up" '''
                ...
              ''';
              down = pkgs.writeShellScript "down" '''
                ...
              ''';
              "theme.toml" = (pkgs.formats.toml {}).generate "theme.toml" {
                border_width = 10;
                margin = 5;
                ...
            };
            "onehalf" = { ... };
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
      (listToAttrs (flatten (mapAttrsToList (name: theme:
        [
          (if isDerivation theme || isStorePath theme then [{
            name = "leftwm/themes/${name}";
            value.source = theme;
          }] else
            mapAttrsToList (file: fs: {
              name = "leftwm/themes/${name}/${file}";
              value = (if isDerivation fs || isStorePath fs then {
                source = fs;
              } else {
                text = fs;
              });
            }) theme)
        ]) cfg.themes)))
    ]);

    home.packages = [ cfg.package ];

    xsession.windowManager.command = "${cfg.package}/bin/leftwm";
  };
}
