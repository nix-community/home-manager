{
  pkgs,
  config,
  lib,
  ...
}:

let

  iniFormat = pkgs.formats.ini { };
  cfg = config.programs.mypy;

in
{
  meta.maintainers = [ ];

  options.programs.mypy = {
    enable = lib.mkEnableOption "mypy";

    package = lib.mkPackageOption pkgs "mypy" { nullable = true; };

    settings = lib.mkOption {
      type = iniFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          mypy = {
            warn_return_any = true;
            warn_unused_configs = true;
          };
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/mypy/config`.

        See <https://mypy.readthedocs.io/en/stable/config_file.html>
        for more information.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."mypy/config" = lib.mkIf (cfg.settings != { }) {
      source = iniFormat.generate "mypy-config" cfg.settings;
    };
  };
}
