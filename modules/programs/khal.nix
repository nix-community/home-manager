# khal config loader is sensitive to leading space !
{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.khal;

  iniFormat = pkgs.formats.ini { };

  khalCalendarAccounts =
    filterAttrs (_: a: a.khal.enable) config.accounts.calendar.accounts;

  # a contact account may have multiple collections, each a separate calendar
  expandContactAccount = name: acct:
    if acct.khal.collections != null then
      listToAttrs (map (c: {
        name = "${name}-${c}";
        value = recursiveUpdate acct { khal.thisCollection = c; };
      }) acct.khal.collections)
    else {
      ${name} = acct;
    };

  khalContactAccounts = concatMapAttrs expandContactAccount
    (mapAttrs (_: v: recursiveUpdate v { khal.type = "birthdays"; })
      (filterAttrs (_: a: a.khal.enable) config.accounts.contact.accounts));

  khalAccounts = khalCalendarAccounts // khalContactAccounts;

  primaryAccount = findSingle (a: a.primary) null null
    (mapAttrsToList (n: v: v // { name = n; }) khalCalendarAccounts);

  definedAttrs = filterAttrs (_: v: !isNull v);

  toKeyValueIfDefined = attrs: generators.toKeyValue { } (definedAttrs attrs);

  genCalendarStr = name: value:
    concatStringsSep "\n" ([
      "[[${name}]]"
      "path = ${
        value.local.path + "/"
        + (optionalString (value.khal.type == "discover") value.khal.glob)
        + (optionalString
          (value.khal.type == "birthdays" && value.khal ? thisCollection)
          value.khal.thisCollection)
      }"
    ] ++ optional (value.khal.readOnly) "readonly = True"
      ++ optional (value.khal.addresses != [ ])
      "addresses= ${lib.concatStringsSep ", " value.khal.addresses}"
      ++ optional (value.khal.color != null) "color = '${value.khal.color}'"
      ++ [ (toKeyValueIfDefined (getAttrs [ "type" "priority" ] value.khal)) ]
      ++ [ "\n" ]);

  localeFormatOptions = let
    T = lib.types;
    suffix = ''
      Format strings are for Python `strftime`, similarly to
      {manpage}`strftime(3)`.
    '';
  in {
    dateformat = mkOption {
      type = T.str;
      default = "%x";
      description = ''
        khal will display and understand all dates in this format.

        ${suffix}
      '';
    };

    timeformat = mkOption {
      type = T.str;
      default = "%X";
      description = ''
        khal will display and understand all times in this format.

        ${suffix}
      '';
    };

    datetimeformat = mkOption {
      type = T.str;
      default = "%c";
      description = ''
        khal will display and understand all datetimes in this format.

        ${suffix}
      '';
    };

    longdateformat = mkOption {
      type = T.str;
      default = "%x";
      description = ''
        khal will display and understand all dates in this format.
        It should contain a year (e.g. `%Y`).

        ${suffix}
      '';
    };

    longdatetimeformat = mkOption {
      type = T.str;
      default = "%c";
      description = ''
        khal will display and understand all datetimes in this format.
        It should contain a year (e.g. `%Y`).

        ${suffix}
      '';
    };
  };

  localeOptions = let T = lib.types;
  in localeFormatOptions // {
    unicode_symbols = mkOption {
      type = T.bool;
      default = true;
      description = ''
        By default khal uses some Unicode symbols (as in "non-ASCII") as
        indicators for things like repeating events.
        If your font, encoding etc. does not support those symbols, set this
        to false (this will enable ASCII-based replacements).
      '';
    };

    default_timezone = mkOption {
      type = T.nullOr T.str;
      default = null;
      description = ''
        Default for new events or if khal does not understand the timezone
        in an ical file.
        If `null`, the timezone of your computer will be used.
      '';
    };

    local_timezone = mkOption {
      type = T.nullOr T.str;
      default = null;
      description = ''
        khal will show all times in this timezone.
        If `null`, the timezone of your computer will be used.
      '';
    };

    firstweekday = mkOption {
      type = T.ints.between 0 6;
      default = 0;
      description = ''
        The first day of the week, where Monday is 0 and Sunday is 6.
      '';
    };

    weeknumbers = mkOption {
      type = T.enum [ "off" "left" "right" ];
      default = "off";
      description = ''
        Enable week numbers in calendar and interactive (ikhal) mode.
        As those are ISO week numbers, they only work properly if
        {option}`firstweekday` is set to 0.
      '';
    };
  };

in {
  options.programs.khal = {
    enable = mkEnableOption "khal, a CLI calendar application";

    locale = mkOption {
      type = lib.types.submodule { options = localeOptions; };
      description = ''
        khal locale settings.
      '';
      default = { };
    };

    settings = mkOption {
      type = iniFormat.type;
      default = { };
      example = literalExpression ''
        {
          default = {
            default_calendar = "Calendar";
            timedelta = "5d";
          };
          view = {
            agenda_event_format =
              "{calendar-color}{cancelled}{start-end-time-style} {title}{repeat-symbol}{reset}";
          };
        }'';
      description = ''
        Configuration options to add to the various sections in the configuration file.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.khal ];

    xdg.configFile."khal/config".text = concatStringsSep "\n" ([ "[calendars]" ]
      ++ mapAttrsToList genCalendarStr khalAccounts ++ [
        (generators.toINI { } (recursiveUpdate cfg.settings {
          locale = definedAttrs (cfg.locale // { _module = null; });

          default = optionalAttrs (!isNull primaryAccount) {
            highlight_event_days = true;
            default_calendar = if isNull primaryAccount.primaryCollection then
              primaryAccount.name
            else
              primaryAccount.primaryCollection;
          };
        }))
      ]);
  };
}
