{ config, lib, ... }:

with lib;

let

  cfg = config.programs.todoman;

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

    color = mkOption {
      type = types.nullOr (types.enum [ "never" "always" ]);
      default = null;
      description = ''
        By default todoman will disable colored output if stdout is not a TTY.
        Set to never to disable colored output entirely, or always to enable it regardless.
      '';
    };

    dateformat = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        The date format used both for displaying dates, and parsing input
        dates. If this option is not specified the system locale’s is used.
      '';
    };

    defaultDue = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = ''
        The default difference (in hours) between new todo’s due date and
        creation date. If not specified, the value is 24. If set to 0,
        the due date for new todos will not be set.
      '';
    };

    defaultList = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        The default list for adding a todo. If you do not specify this option,
        you must use the `--list` / `-l` option every time you add a todo.
      '';
    };

    defaultPriority = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = ''
        The default priority of a task on creation. Highest priority is 1,
        lowest priority is 10, and 0 means no priority at all.
      '';
    };

    dtSeparator = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        The string used to separate date and time when displaying and parsing.
      '';
    };

    humanize = mkOption {
      type = types.bool;
      default = false;
      description = ''
        If set to true, datetimes will be printed in human friendly formats like
        “tomorrow”, “in one hour”, “3 weeks ago”, etc.
      '';
    };

    startable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        If set to true, only show todos which are currently startable;
        these are todos which have a start date today, or some day in the past.
        Todos with no start date are always considered current. Incomplete todos
        (eg: partially-complete) are also included.
      '';
    };

    timeformat = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        The date format used both for displaying times, and parsing input times.
        If this option is not specified the system locale’s is used.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = accounts.calendar ? basePath;
        message = ''
          A base directory for calendars must be specified via
          `accounts.calendar.basePath` to generate config for todoman
        '';
      }
      {
        assertion = 0 <= cfg.defaultPriority && cfg.defaultPriority <= 10;
        message = "Todoman's `defaultPriority` must be between 0 and 10.";
      }
    ];

    home.packages = [ pkgs.todoman ];

    xdg.configFile."todoman/config.py".text = generators.toINI cfg;
  };
}
