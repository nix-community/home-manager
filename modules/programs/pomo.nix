{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    mkPackageOption
    ;
  cfg = config.programs.pomo;
  yamlFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = [ lib.maintainers.rachitvrma ];

  options.programs.pomo = {
    enable = mkEnableOption ''
      pomo, a TUI Pomodoro timer with ASCII Art, progress bar,
      desktop notifications, and productivity stats.
    '';

    package = mkPackageOption pkgs "pomo" { nullable = true; };

    settings = mkOption {
      inherit (yamlFormat) type;
      default = { };
      example = {
        onSessionEnd = "ask";

        asciiArt = {
          enabled = true;
          font = "mono12";
          color = "#5A56E0";
        };

        work = {
          duration = "25m";
          title = "work session";
          notification = {
            enabled = true;
            urgent = false;
            title = "work finished 🎉";
            message = "time to take a break";
          };
        };
      };

      description = ''
        Configuration written to
        {file}`$HOME/.config/pomo/pomo.yml`
        See <https://github.com/Bahaaio/pomo/blob/main/pomo.yaml>
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    home.file.".config/pomo/pomo.yaml" = mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "hm_pomo.yaml" cfg.settings;
    };
  };
}
