{ config, lib, pkgs, ... }:
let cfg = config.programs.todoman;
in {

  meta.maintainers = [ lib.hm.maintainers.mikilio ];

  options.programs.todoman = {
    enable = lib.mkEnableOption "todoman";

    package = lib.mkPackageOption pkgs "todoman" { nullable = true; };

    glob = lib.mkOption {
      type = lib.types.str;
      default = "*";
      description = ''
        The glob expansion which matches all directories relevant.
      '';
      example = "*/*";
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Text for configuration of todoman.
        The syntax is Python.

        See [docs](`https://todoman.readthedocs.io/en/stable/man.html#id5`).
        for the full list of options.
      '';
      example = ''
        date_format = "%Y-%m-%d";
        time_format = "%H:%M";
        default_list = "Personal";
        default_due = 48;
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [{
      assertion = config.accounts.calendar ? basePath;
      message = ''
        A base directory for calendars must be specified via
        `accounts.calendar.basePath` to generate config for todoman
      '';
    }];

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."todoman/config.py".text = lib.concatLines [
      ''path = "${config.accounts.calendar.basePath}/${cfg.glob}"''
      cfg.extraConfig
    ];
  };
}
