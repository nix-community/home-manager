# khal config loader is sensitive to leading space !
{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.khal;

  khalCalendarAccounts =
    filterAttrs (_: a: a.khal.enable) config.accounts.calendar.accounts;

  khalContactAccounts =
    mapAttrs (_: v: v // { type = "birthdays"; })
    (filterAttrs (_: a: a.khal.enable) config.accounts.contact.accounts);

  khalAccounts = khalCalendarAccounts // khalContactAccounts;

  primaryAccount =
    findSingle (a: a.primary) null null
    (mapAttrsToList (n: v: v // {name= n;}) khalAccounts);

  genCalendarStr = name: value:
    concatStringsSep "\n" (
      [
        "[[${name}]]"
        "path = ${value.local.path + "/" + (optionalString (value.khal.type == "discover") value.khal.glob)}"
      ]
      ++ optional (value.khal.readOnly) "readonly = True"
      ++ optional (!isNull value.khal.type) "type = ${value.khal.type}"
      ++ ["\n"]
    );

in

{
  options.programs.khal = {
    enable = mkEnableOption "khal, a CLI calendar application";
  };

  config = mkIf cfg.enable {
    home.packages =  [ pkgs.khal ];

    xdg.configFile."khal/config".text = concatStringsSep "\n" (
      [
        "[calendars]"
      ]
      ++ mapAttrsToList genCalendarStr khalAccounts
      ++
      [
        (generators.toINI {} {
          default = optionalAttrs (!isNull primaryAccount) {
            default_calendar = if isNull primaryAccount.primaryCollection then primaryAccount.name else primaryAccount.primaryCollection;
          };

          locale = {
            timeformat = "%H:%M";
            dateformat = "%Y-%m-%d";
            longdateformat = "%Y-%m-%d";
            datetimeformat = "%Y-%m-%d %H:%M";
            longdatetimeformat = "%Y-%m-%d %H:%M";
            weeknumbers = "right";
          };
        })
      ]
    );
  };
}
