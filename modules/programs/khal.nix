# khal config loader is sensitive to leading space !
{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.khal;

  khalCalendarAccounts =
    filterAttrs (_: a: a.khal.enable) config.accounts.calendar.accounts;

  khalContactAccounts = mapAttrs (_: v: v // { type = "birthdays"; })
    (filterAttrs (_: a: a.khal.enable) config.accounts.contact.accounts);

  khalAccounts = khalCalendarAccounts // khalContactAccounts;

  primaryAccount = findSingle (a: a.primary) null null
    (mapAttrsToList (n: v: v // { name = n; }) khalAccounts);

  definedAttrs = filterAttrs (_: v: !isNull v);

  toKeyValueIfDefined = attrs: generators.toKeyValue { } (definedAttrs attrs);

  genCalendarStr = name: value:
    concatStringsSep "\n" ([
      "[[${name}]]"
      "path = ${
        value.local.path + "/"
        + (optionalString (value.khal.type == "discover") value.khal.glob)
      }"
    ] ++ optional (value.khal.readOnly) "readonly = True" ++ [
      (toKeyValueIfDefined (getAttrs [ "type" "color" "priority" ] value.khal))
    ] ++ [ "\n" ]);

  localeFormatOptions = let T = lib.types;
  in mapAttrs (n: v:
    v // {
      description = v.description + ''

        Format strings are for python 'strftime', similarly to man 3 strftime.
      '';
    }) {
      dateformat = {
        type = T.str;
        default = "%x";
        description = ''
          khal will display and understand all dates in this format.
        '';
      };

      timeformat = {
        type = T.str;
        default = "%X";
        description = ''
          khal will display and understand all times in this format.
        '';
      };

      datetimeformat = {
        type = T.str;
        default = "%c";
        description = ''
          khal will display and understand all datetimes in this format.
        '';
      };

      longdateformat = {
        type = T.str;
        default = "%x";
        description = ''
          khal will display and understand all dates in this format.
          It should contain a year (e.g. %Y).
        '';
      };

      longdatetimeformat = {
        type = T.str;
        default = "%c";
        description = ''
          khal will display and understand all datetimes in this format.
          It should contain a year (e.g. %Y).
        '';
      };
    };

  localeOptions = let T = lib.types;
  in localeFormatOptions // {
    unicode_symbols = {
      type = T.bool;
      default = true;
      description = ''
        By default khal uses some unicode symbols (as in ‘non-ascii’) as
        indicators for things like repeating events.
        If your font, encoding etc. does not support those symbols, set this
        to false (this will enable ascii based replacements).
      '';
    };

    default_timezone = {
      type = T.nullOr T.str;
      default = null;
      description = ''
        Default for new events or if khal does not understand the timezone
        in an ical file.
        If 'null', the timezone of your computer will be used.
      '';
    };

    local_timezone = {
      type = T.nullOr T.str;
      default = null;
      description = ''
        khal will show all times in this timezone.
        If 'null', the timezone of your computer will be used.
      '';
    };

    firstweekday = {
      type = T.ints.between 0 6;
      default = 0;
      description = ''
        the first day of the week, where Monday is 0 and Sunday is 6
      '';
    };

    weeknumbers = {
      type = T.enum [ "off" "left" "right" ];
      default = "off";
      description = ''
        Enable weeknumbers in calendar and interactive (ikhal) mode.
        As those are iso weeknumbers, they only work properly if firstweekday
        is set to 0.
      '';
    };
  };

in {
  options.programs.khal = {
    enable = mkEnableOption "khal, a CLI calendar application";
    locale = mkOption {
      type = lib.types.submodule {
        options = mapAttrs (n: v: mkOption v) localeOptions;
      };
      description = ''
        khal locale settings. 
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.khal ];

    xdg.configFile."khal/config".text = concatStringsSep "\n" ([ "[calendars]" ]
      ++ mapAttrsToList genCalendarStr khalAccounts ++ [
        (generators.toINI { } {
          locale = definedAttrs (cfg.locale // { _module = null; });

          default = optionalAttrs (!isNull primaryAccount) {
            default_calendar = if isNull primaryAccount.primaryCollection then
              primaryAccount.name
            else
              primaryAccount.primaryCollection;
          };
        })
      ]);
  };
}
