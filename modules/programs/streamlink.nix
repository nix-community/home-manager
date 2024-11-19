{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.streamlink;

  renderSettings = mapAttrsToList (name: value:
    if (builtins.isBool value) then
      if value then name else ""
    else
      if (builtins.isList value) then
        concatStringsSep "\n" (builtins.map (item: "${name}=${builtins.toString item}") value)
      else
        "${name}=${builtins.toString value}");

  pluginType = types.submodule {
    options = {
      src = mkOption {
        type = with types; nullOr (either path lines);
        default = null;
        description = ''
          Source of the custom plugin. The value should be a path to the
          plugin file, or the text of the plugin code. Will be linked to
          {file}`$XDG_DATA_HOME/streamlink/plugins/<name>.py` (linux) or
          {file}`Library/Application Support/streamlink/plugins/<name>.py` (darwin).
        '';
        example = literalExpression "./custom_plugin.py";
      };

      settings = mkOption {
        type = with types; attrsOf (oneOf [ bool int str (listOf (either int str)) ]);
        default = { };
        example = literalExpression ''
          {
            quiet = true;
          }
        '';
        description = ''
          Configuration for the specific plugin, written to
          {file}`$XDG_CONFIG_HOME/streamlink/config.<name>` (linux) or
          {file}`Library/Application Support/streamlink/config.<name>` (darwin).
        '';
      };
    };
  };

in {
  meta.maintainers = with maintainers; [ folliehiyuki ];

  options.programs.streamlink = {
    enable = mkEnableOption "streamlink";

    package = mkPackageOption pkgs "streamlink" { };

    settings = mkOption {
      type = with types; attrsOf (oneOf [ bool int str (listOf (either int str)) ]);
      default = { };
      example = literalExpression ''
        {
          player = "''${pkgs.mpv}/bin/mpv";
          player-args = "--cache 2048";
          player-no-close = true;
        }
      '';
      description = ''
        Global configuration options for streamlink. It will be written to
        {file}`$XDG_CONFIG_HOME/streamlink/config` (linux) or
        {file}`Library/Application Support/streamlink/config` (darwin).
      '';
    };

    plugins = mkOption {
      description = ''
        Streamlink plugins.

        If a source is set, the custom plugin will be linked to the data directory.

        Additional configuration specific to the plugin, if defined, will be
        written to the config directory, and override global settings.
      '';
      type = types.attrsOf pluginType;
      default = { };
      example = literalExpression ''
        {
          custom_plugin = {
            src = ./custom_plugin.py;
            settings = {
              quiet = true;
            };
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file = mkIf pkgs.stdenv.isDarwin {
      "Library/Application Support/streamlink/config" =
        mkIf (cfg.settings != { }) {
          text = concatStringsSep "\n" (remove "" (renderSettings cfg.settings))
            + "\n";
        };
    } // (mapAttrs' (name: value:
      nameValuePair "Library/Application Support/streamlink/config.${name}"
      (mkIf (value.settings != { }) {
        text = concatStringsSep "\n" (remove "" (renderSettings value.settings))
          + "\n";
      })) cfg.plugins) // (mapAttrs' (name: value:
        nameValuePair
        "Library/Application Support/streamlink/plugins/${name}.py"
        (mkIf (value.src != null) (if (builtins.isPath value.src) then {
          source = value.src;
        } else {
          text = value.src;
        }))) cfg.plugins);

    xdg.configFile = mkIf pkgs.stdenv.isLinux ({
      "streamlink/config" = mkIf (cfg.settings != { }) {
        text = concatStringsSep "\n" (remove "" (renderSettings cfg.settings))
          + "\n";
      };
    } // (mapAttrs' (name: value:
      nameValuePair "streamlink/config.${name}" (mkIf (value.settings != { }) {
        text = concatStringsSep "\n" (remove "" (renderSettings value.settings))
          + "\n";
      })) cfg.plugins));

    xdg.dataFile = mkIf pkgs.stdenv.isLinux (mapAttrs' (name: value:
      nameValuePair "streamlink/plugins/${name}.py" (mkIf (value.src != null)
        (if (builtins.isPath value.src) then {
          source = value.src;
        } else {
          text = value.src;
        }))) cfg.plugins);
  };
}
