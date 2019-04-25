{ config, lib, pkgs, ... }:

with lib;

let
 
  config = cfg.accounts.calendar;

#  calendarOpts = { name, config, ... }: {
#    options = {
#      name = mkOption {
#        type = types.str;
#        readOnly = true;
#        description = ''
#          Unique identifier of the calendar. This is set to the
#          attribute name of the calendar configuration.
#        '';
#      };
#    };
#
#    config = mkMerge [ { name = name; } ];
#  };

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
#        calendarOpts
        (import ../programs/vdirsyncer-accounts.nix)
      ]);
      default = {};
      description = "List of calendars.";
    };
  };
}
