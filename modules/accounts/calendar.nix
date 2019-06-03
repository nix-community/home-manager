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

      path = mkOption {
        type = types.str;
        default = "${cfg.basePath}/${name}";
        description = "The path of the storage.";
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
        type = types.str;
        description = ''
          The primary collection of the account. Required when an account has
          multiple collections.
        '';
      };
    };

    config = mkMerge [
      {
        name = name;
        khal.type = mkOptionDefault null;
      }
    ];
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
    assertions =
      let
        primaries =
          catAttrs "name"
          (filter (a: a.primary)
          (attrValues cfg.accounts));
      in
        [{
          assertion = length primaries <= 1;
          message =
            "Must have at most one primary calendar accounts but found "
            + toString (length primaries)
            + ", namely "
            + concatStringsSep ", " primaries;
        }];
  };
}
