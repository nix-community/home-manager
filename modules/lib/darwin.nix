{ lib }:
let
  intervals = [
    "hourly"
    "daily"
    "weekly"
    "monthly"
    "semiannually"
    "annually"
  ];

  mkCalendarInterval =
    frequency:
    let
      freq = {
        "hourly" = [ { Minute = 0; } ];
        "daily" = [
          {
            Hour = 0;
            Minute = 0;
          }
        ];
        "weekly" = [
          {
            Weekday = 1;
            Hour = 0;
            Minute = 0;
          }
        ];
        "monthly" = [
          {
            Day = 1;
            Hour = 0;
            Minute = 0;
          }
        ];
        "semiannually" = [
          {
            Month = 1;
            Day = 1;
            Hour = 0;
            Minute = 0;
          }
          {
            Month = 7;
            Day = 1;
            Hour = 0;
            Minute = 0;
          }
        ];
        "annually" = [
          {
            Month = 1;
            Day = 1;
            Hour = 0;
            Minute = 0;
          }
        ];
      };
    in
    freq.${frequency} or null;

  intervalsString = lib.concatStringsSep ", " intervals;

  assertInterval = option: interval: pkgs: {
    assertion = (!pkgs.stdenv.isDarwin) || (lib.elem interval intervals);
    message = "On Darwin ${option} must be one of: ${intervalsString}.";
  };

  intervalDocumentation = ''
    On Darwin it must be one of: ${intervalsString}, which are implemented as defined in {manpage}`systemd.time(7)`.
  '';
in
{
  inherit mkCalendarInterval assertInterval intervalDocumentation;
}
