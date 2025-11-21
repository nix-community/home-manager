{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.programs.ncspot;

  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = [ lib.maintainers.awwpotato ];

  options.programs.ncspot = {
    enable = lib.mkEnableOption "ncspot";

    package = lib.mkPackageOption pkgs "ncspot" { nullable = true; };

    settings = lib.mkOption {
      type = tomlFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          shuffle = true;
          gapless = true;
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/ncspot/config.toml`.

        See <https://github.com/hrkfdn/ncspot#configuration>
        for the full list of options.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."ncspot/config.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "ncspot-config" cfg.settings;
    };
  };
}
