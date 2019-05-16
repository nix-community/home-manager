# khal config loader is sensitive to leading space !
{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.khal;

  khalAccounts = filterAttrs (_: a: a.khal.enable)
    (config.accounts.calendar.accounts);
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
    ++ (mapAttrsToList (name: value: concatStringsSep "\n"
      ([
        ''[[${name}]]''
        ''path = ${value.path + "/" + (optionalString (value.khal.type == "discover") value.khal.glob)}''
      ]
      ++ optional (value.khal.readOnly) "readonly = True"
      ++ optional (!isNull value.khal.type) "type = ${value.khal.type}"
      ++ ["\n"]
      )
      ) khalAccounts)
    ++
    [
    (generators.toINI {} {
      default = {
        default_calendar = head (mapAttrsToList (n: v: baseNameOf v.path) (filterAttrs (_: a: a.primary) khalAccounts));
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
