{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.todoman;

  format = pkgs.formats.keyValue { };

in {

  meta.maintainers = [ hm.maintainers.mikilio ];

  options.programs.todoman = {
    enable = lib.mkEnableOption "todoman";

    glob = mkOption {
      type = types.str;
      default = "*";
      description = ''
        The glob expansion which matches all directories relevant.
      '';
      example = "*/*";
    };

    extraConfig = mkOption {
      type = types.lines;
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

  config = mkIf cfg.enable {
    assertions = [{
      assertion = config.accounts.calendar ? basePath;
      message = ''
        A base directory for calendars must be specified via
        `accounts.calendar.basePath` to generate config for todoman
      '';
    }];

    home.packages = [ pkgs.todoman ];

    xdg.configFile."todoman/config.py".text = lib.concatLines [
      ''path = "${config.accounts.calendar.basePath}/${cfg.glob}"''
      cfg.config
    ];
  };
}
