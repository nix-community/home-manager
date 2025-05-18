{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.ncspot;

  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = [ ];

  options.programs.ncspot = {
    enable = lib.mkEnableOption "ncspot";

    package = lib.mkPackageOption pkgs "ncspot" { };

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

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."ncspot/config.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "ncspot-config" cfg.settings;
    };
  };
}
