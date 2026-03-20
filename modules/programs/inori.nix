{
  lib,
  config,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkOption
    mkEnableOption
    mkPackageOption
    literalExpression
    mkIf
    hm
    maintainers
    ;

  cfg = config.programs.inori;

  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = [
    hm.maintainers.lunahd
    maintainers.stephen-huan
  ];

  options.programs.inori = {
    enable = mkEnableOption "inori";

    package = mkPackageOption pkgs "inori" { nullable = true; };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      example = literalExpression ''
        {
          seek_seconds = 10;
          dvorak_keybindings = true;
        }
      '';
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/inori/config.toml`.

        See <https://github.com/eshrh/inori/blob/master/CONFIGURATION.md> for available options.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."inori/config.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "config.toml" cfg.settings;
    };
  };
}
