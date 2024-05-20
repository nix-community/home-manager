{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.nix.gc;
  darwinIntervals =
    [ "hourly" "daily" "weekly" "monthly" "semiannually" "annually" ];

  mkCalendarInterval = frequency:
    let
      freq = {
        "hourly" = [{ Minute = 0; }];
        "daily" = [{
          Hour = 0;
          Minute = 0;
        }];
        "weekly" = [{
          Weekday = 1;
          Hour = 0;
          Minute = 0;
        }];
        "monthly" = [{
          Day = 1;
          Hour = 0;
          Minute = 0;
        }];
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
        "annually" = [{
          Month = 1;
          Day = 1;
          Hour = 0;
          Minute = 0;
        }];
      };
    in freq.${frequency};

  nixPackage = if config.nix.enable && config.nix.package != null then
    config.nix.package
  else
    pkgs.nix;
in {
  meta.maintainers = [ maintainers.shivaraj-bh ];

  options = {
    nix.gc = {
      automatic = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Automatically run the garbage collector at a specific time.

          Note: This will only garbage collect the current user's profiles.
        '';
      };

      frequency = mkOption {
        type = types.str;
        default = "weekly";
        example = "03:15";
        description = ''
          When to run the Nix garbage collector.

          On Linux this is a string as defined by {manpage}`systemd.time(7)`.

          On Darwin it must be one of: ${toString darwinIntervals}, which are
          implemented as defined in the manual page above.
        '';
      };

      options = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "--max-freed $((64 * 1024**3))";
        description = ''
          Options given to {file}`nix-collect-garbage` when the
          garbage collector is run automatically.
        '';
      };
    };
  };

  config = lib.mkIf cfg.automatic (mkMerge [
    (mkIf pkgs.stdenv.isLinux {
      systemd.user.services.nix-gc = {
        Unit = { Description = "Nix Garbage Collector"; };
        Service = {
          ExecStart = "${nixPackage}/bin/nix-collect-garbage ${
              lib.optionalString (cfg.options != null) cfg.options
            }";
        };
      };
      systemd.user.timers.nix-gc = {
        Unit = { Description = "Nix Garbage Collector"; };
        Timer = {
          OnCalendar = "${cfg.frequency}";
          Unit = "nix-gc.service";
        };
        Install = { WantedBy = [ "timers.target" ]; };
      };
    })

    (mkIf pkgs.stdenv.isDarwin {
      assertions = [{
        assertion = elem cfg.frequency darwinIntervals;
        message = "On Darwin nix.gc.frequency must be one of: ${
            toString darwinIntervals
          }.";
      }];

      launchd.agents.nix-gc = {
        enable = true;
        config = {
          ProgramArguments = [ "${nixPackage}/bin/nix-collect-garbage" ]
            ++ lib.optional (cfg.options != null) cfg.options;
          StartCalendarInterval = mkCalendarInterval cfg.frequency;
        };
      };
    })
  ]);
}
