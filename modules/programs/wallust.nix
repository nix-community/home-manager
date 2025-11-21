{
  pkgs,
  lib,
  config,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkPackageOption
    mkOption
    mkIf
    literalExpression
    ;
  cfg = config.programs.wallust;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = with lib.maintainers; [ kiara ];

  options.programs.wallust = {
    enable = mkEnableOption "Wallust color scheme generator";

    package = mkPackageOption pkgs "wallust" { nullable = true; };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      example = literalExpression ''
        {
          palette = "softdark";
        }
      '';
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/wallust/wallust.toml`.
        See <https://explosion-mental.codeberg.page/wallust/config/> for
        documentation.
      '';
    };
  };
  config = mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."wallust/wallust.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "wallust.toml" cfg.settings;
    };
  };
}
