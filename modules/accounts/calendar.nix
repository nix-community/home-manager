{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.accounts.calendar;

  localModule = name:
    types.submodule {
      options = {
        path = mkOption {
          type = types.str;
          default = "${cfg.basePath}/${name}";
          defaultText = "‹accounts.calendar.basePath›/‹name›";
          description = "The path of the storage.";
        };

        type = mkOption {
          type = types.enum [ "filesystem" "singlefile" ];
          default = "filesystem";
          description = "The type of the storage.";
        };

        fileExt = mkOption {
          type = types.nullOr types.str;
          default = ".ics";
          description = "The file extension to use.";
        };

        encoding = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            File encoding for items, both content and file name.
            Defaults to UTF-8.
          '';
        };
      };
    };

  remoteModule = types.submodule {
    options = {
      type = mkOption {
        type = types.enum [ "caldav" "http" "google_calendar" ];
        description = "The type of the storage.";
      };

      url = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The URL of the storage.";
      };

      userName = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "User name for authentication.";
      };

      passwordCommand = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        example = [ "pass" "caldav" ];
        description = ''
          A command that prints the password to standard output.
        '';
      };
    };
  };

  calendarOpts = { name, config, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        readOnly = true;
        description = ''
          Unique identifier of the calendar. This is set to the
          attribute name of the calendar configuration.
        '';
      };

      primary = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether this is the primary account. Only one account may be
          set as primary.
        '';
      };

      primaryCollection = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          The primary collection of the account. Required when an
          account has multiple collections.
        '';
      };

      local = mkOption {
        type = localModule name;
        default = { };
        description = ''
          Local configuration for the calendar.
        '';
      };

      remote = mkOption {
        type = types.nullOr remoteModule;
        default = null;
        description = ''
          Remote configuration for the calendar.
        '';
      };
    };

    config = { name = name; };
  };

in {
  options.accounts.calendar = {
    basePath = mkOption {
      type = types.str;
      example = ".calendar";
      apply = p:
        if hasPrefix "/" p then p else "${config.home.homeDirectory}/${p}";
      description = ''
        The base directory in which to save calendars. May be a
        relative path, in which case it is relative the home
        directory.
      '';
    };

    accounts = mkOption {
      type = types.attrsOf (types.submodule [
        calendarOpts
        (import ../programs/vdirsyncer-accounts.nix)
        (import ../programs/khal-accounts.nix)
        (import ../programs/khal-calendar-accounts.nix)
      ]);
      default = { };
      description = "List of calendars.";
    };
  };
  config = mkIf (cfg.accounts != { }) {
    assertions = let
      primaries =
        catAttrs "name" (filter (a: a.primary) (attrValues cfg.accounts));
    in [{
      assertion = length primaries <= 1;
      message = "Must have at most one primary calendar account but found "
        + toString (length primaries) + ", namely "
        + concatStringsSep ", " primaries;
    }];
  };
}
