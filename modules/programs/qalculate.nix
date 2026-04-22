{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.qalculate;

  iniFormat = pkgs.formats.ini { };
in
{
  meta.maintainers = [ lib.maintainers.philocalyst ];

  options.programs.qalculate = {
    enable = lib.mkEnableOption "Qalculate!, a multi-purpose desktop calculator";

    package = lib.mkPackageOption pkgs "libqalculate" {
      nullable = true;
      example = "pkgs.qalculate-gtk";
    };

    settings = lib.mkOption {
      inherit (iniFormat) type;
      default = { };
      example = lib.literalExpression ''
        {
          General = {
            precision = 10;
            colorize = 1;
            save_mode_on_exit = 1;
            save_definitions_on_exit = 0;
          };
          Mode = {
            angle_unit = 1;
            number_base = 10;
            min_deci = 0;
            max_deci = -1;
          };
        }
      '';

      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/qalculate/qalc.cfg`.

        Settings are organized into two INI sections:

        - `General` — persistence and display preferences (e.g.
          `save_mode_on_exit`, `colorize`, `precision`).
        - `Mode` — active calculator settings that mirror the options
          accepted by the {command}`set` command in an interactive
          {command}`qalc` session (e.g. `angle_unit`, `number_base`,
          `min_deci`).

        See {manpage}`qalc(1)` for the full list of available settings
        and their accepted values.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."qalculate/qalc.cfg" = lib.mkIf (cfg.settings != { }) {
      source = iniFormat.generate "qalc.cfg" cfg.settings;
    };
  };
}
