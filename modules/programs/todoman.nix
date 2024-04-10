{ config, lib, ... }:

with lib;

let

  cfg = config.programs.todoman;
  iniFormat = pkgs.formats.ini { };

in {

  meta.maintainers = [ maintainers.mikilio ];

  options.todoman = {
    enable = lib.mkEnableOption
      "Enable todoman a standards-based task manager based on iCalendar";

    glob = mkOption {
      type = types.str;
      default = "*";
      description = ''
        The glob expansion which matches all directories relevant.
      '';
    };
    settings = mkOption {
      type = iniFormat.type;
      default = { };
      description = ''
        Configuration for todoman

        See [docs](`https://todoman.readthedocs.io/en/stable/man.html#id5`).
        for the full list of options.
      '';
      example = literalExpression ''
        {
          date_format = "%Y-%m-%d";
          time_format = "%H:%M";
          default_list = "Personal";
          default_due = 48;
        };
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Additional lines for configuration of todoman

        See [docs](`https://todoman.readthedocs.io/en/stable/man.html#id5`).
        for the full list of options.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = accounts.calendar ? basePath;
      message = ''
        A base directory for calendars must be specified via
        `accounts.calendar.basePath` to generate config for todoman
      '';
    }];

    home.packages = [ pkgs.todoman ];

    xdg.configFile."todoman/config.py" =
      mkIf (cfg.settings != { } && cfg.extraConfig != "") {
        text = lib.concatLines [
          ''path = "~/${config.accounts.calendar.basePath}${cfg.glob}"''
          (generators.toINI { } cfg.settings)
          cfg.extraConfig
        ];
      };
  };
}
