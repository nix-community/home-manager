{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.accounts.calendar;

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
    };

    config = mkMerge [ { name = name; } ];
  };

in

{
  options.accounts.calendar = {
    basePath = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.calendars/";
      defaultText = "$HOME/.calendars";
      description = ''
        The base directory in which to save calendars.
      '';
    };

    accounts = mkOption {
      type = types.attrsOf (types.submodule [
        calendarOpts
        (import ../programs/vdirsyncer-accounts.nix)
        (import ../programs/khal-accounts.nix)
      ]);
      default = {};
      description = "List of calendars.";
    };
  };
  config = mkIf (cfg.accounts != {}) {
    assertions = [
      (
        let
          primaries =
            catAttrs "name"
            (filter (a: a.primary)
            (attrValues cfg.accounts));
        in
          {
            assertion = length primaries == 1;
            message =
              "Must have exactly one primary calendar account but found "
              + toString (length primaries)
              + optionalString (length primaries > 1)
                  (", namely " + concatStringsSep ", " primaries);
          }
      )
    ] ++
      map (a:
          {
            assertion = a.khal.type != "birthdays";
            message =
              a.name
              + " is a calendar account so type can't be birthdays";
            })
            (filter (a: a.khal.enable)
            (attrValues cfg.accounts));
  };
}
