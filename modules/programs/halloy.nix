{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    types
    ;

  cfg = config.programs.halloy;

  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

  options.programs.halloy = {
    enable = mkEnableOption "halloy";
    package = mkPackageOption pkgs "halloy" { nullable = true; };
    settings = mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        "buffer.channel.topic".enabled = true;
        "servers.liberachat" = {
          nickname = "halloy-user";
          server = "irc.libera.chat";
          channels = [ "#halloy" ];
        };
      };
      description = ''
        Configuration settings for halloy. All available options can be
        found here: <https://halloy.chat/configuration/index.html>.
      '';
    };
    themes = mkOption {
      type = types.attrsOf (
        types.oneOf [
          tomlFormat.type
          types.lines
          types.path
        ]
      );
      default = { };
      example = {
        general = {
          background = "<string>";
          border = "<string>";
          horizontal_rule = "<string>";
          unread_indicator = "<string>";
        };
        text = {
          primary = "<string>";
          secondary = "<string>";
          tertiary = "<string>";
          success = "<string>";
          error = "<string>";
        };
      };
      description = ''
        Each theme is written to {file}`$XDG_CONFIG_HOME/halloy/themes/NAME.toml`.
        See <https://halloy.chat/configuration/themes/index.html> for more information.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile = lib.mkMerge [
      {
        "halloy/config.toml" = mkIf (cfg.settings != { }) {
          source = tomlFormat.generate "halloy-config" cfg.settings;
        };
      }
      (lib.mapAttrs' (
        name: value:
        lib.nameValuePair "halloy/themes/${name}.toml" {
          source =
            if lib.isString value then
              pkgs.writeText "halloy-theme-${name}" value
            else if builtins.isPath value || lib.isStorePath value then
              value
            else
              tomlFormat.generate "halloy-theme-${name}" value;
        }
      ) cfg.themes)
    ];
  };
}
