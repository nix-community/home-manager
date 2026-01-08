{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.programs.streamlink;

  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin then "Library/Application Support" else config.xdg.configHome;
  dataDir =
    if pkgs.stdenv.hostPlatform.isDarwin then "Library/Application Support" else config.xdg.dataHome;

  renderSettings =
    settings:
    lib.concatLines (
      lib.remove "" (
        lib.mapAttrsToList (
          name: value:
          if (builtins.isBool value) then
            if value then name else ""
          else if (builtins.isList value) then
            lib.concatStringsSep "\n" (map (item: "${name}=${toString item}") value)
          else
            "${name}=${toString value}"
        ) settings
      )
    );

  pluginType = lib.types.submodule {
    options = {
      src = lib.mkOption {
        type = with lib.types; nullOr (either path lines);
        default = null;
        description = ''
          Source of the custom plugin. The value should be a path to the
          plugin file, or the text of the plugin code. Will be linked to
          {file}`$XDG_DATA_HOME/streamlink/plugins/<name>.py` (linux) or
          {file}`Library/Application Support/streamlink/plugins/<name>.py` (darwin).
        '';
        example = lib.literalExpression "./custom_plugin.py";
      };

      settings = lib.mkOption {
        type =
          with lib.types;
          attrsOf (oneOf [
            bool
            int
            float
            str
            (listOf (oneOf [
              int
              float
              str
            ]))
          ]);
        default = { };
        example = lib.literalExpression ''
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

in
{
  meta.maintainers = [ lib.hm.maintainers.folliehiyuki ];

  options.programs.streamlink = {
    enable = lib.mkEnableOption "streamlink";

    package = lib.mkPackageOption pkgs "streamlink" { nullable = true; };

    settings = lib.mkOption {
      type =
        with lib.types;
        attrsOf (oneOf [
          bool
          int
          float
          str
          (listOf (oneOf [
            int
            float
            str
          ]))
        ]);
      default = { };
      example = lib.literalExpression ''
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

    plugins = lib.mkOption {
      description = ''
        Streamlink plugins.

        If a source is set, the custom plugin will be linked to the data directory.

        Additional configuration specific to the plugin, if defined, will be
        written to the config directory, and override global settings.
      '';
      type = lib.types.attrsOf pluginType;
      default = { };
      example = lib.literalExpression ''
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

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    home.file = {
      "${configDir}/streamlink/config" = lib.mkIf (cfg.settings != { }) {
        text = renderSettings cfg.settings;
      };
    }
    // (lib.mapAttrs' (
      name: value:
      lib.nameValuePair "${configDir}/streamlink/config.${name}" (
        lib.mkIf (value.settings != { }) {
          text = renderSettings value.settings;
        }
      )
    ) cfg.plugins)
    // (lib.mapAttrs' (
      name: value:
      lib.nameValuePair "${dataDir}/streamlink/plugins/${name}.py" (
        lib.mkIf (value.src != null) (
          if (builtins.isPath value.src) then
            {
              source = value.src;
            }
          else
            {
              text = value.src;
            }
        )
      )
    ) cfg.plugins);
  };
}
