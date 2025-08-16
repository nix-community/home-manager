{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkChangedOptionModule mkOption types;

  cfg = config.nix.gc;

  nixPackage =
    if config.nix.enable && config.nix.package != null then config.nix.package else pkgs.nix;
in
{
  meta.maintainers = [ lib.maintainers.shivaraj-bh ];

  imports = [
    (mkChangedOptionModule [ "nix" "gc" "frequency" ] [ "nix" "gc" "dates" ] (
      config: lib.toList (lib.getAttrFromPath [ "nix" "gc" "frequency" ] config)
    ))
  ];

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

      dates = mkOption {
        type = with types; either singleLineStr (listOf str);
        apply = lib.toList;
        default = "weekly";
        example = "03:15";
        description = ''
          When to run the Nix garbage collector.

          On Linux this is a string as defined by {manpage}`systemd.time(7)`.

          ${lib.hm.darwin.intervalDocumentation}
        '';
      };

      randomizedDelaySec = lib.mkOption {
        default = "0";
        type = lib.types.singleLineStr;
        example = "45min";
        description = ''
          Add a randomized delay before each garbage collection.
          The delay will be chosen between zero and this value.
          This value must be a time span in the format specified by
          {manpage}`systemd.time(7)`
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

      persistent = mkOption {
        type = types.bool;
        default = true;
        example = false;
        description = ''
          If true, the time when the service unit was last triggered is
          stored on disk. When the timer is activated, the service unit is
          triggered immediately if it would have been triggered at least once
          during the time when the timer was inactive.
        '';
      };
    };
  };

  config = lib.mkIf cfg.automatic (
    lib.mkMerge [
      (lib.mkIf pkgs.stdenv.isLinux {
        systemd.user.services.nix-gc = {
          Unit = {
            Description = "Nix Garbage Collector";
          };
          Service = {
            Type = "oneshot";
            ExecStart = toString (
              pkgs.writeShellScript "nix-gc" "exec ${nixPackage}/bin/nix-collect-garbage ${
                lib.optionalString (cfg.options != null) cfg.options
              }"
            );
          };
        };
        systemd.user.timers.nix-gc = {
          Unit = {
            Description = "Nix Garbage Collector";
          };
          Timer = {
            OnCalendar = cfg.dates;
            RandomizedDelaySec = cfg.randomizedDelaySec;
            Persistent = cfg.persistent;
            Unit = "nix-gc.service";
          };
          Install = {
            WantedBy = [ "timers.target" ];
          };
        };
      })

      (lib.mkIf pkgs.stdenv.isDarwin {
        assertions = [
          {
            assertion = (lib.length cfg.dates) == 1;
            message = "On Darwin, `nix.gc.dates` must contain a single element.";
          }
          (lib.hm.darwin.assertInterval "nix.gc.dates.*" (lib.elemAt cfg.dates 0) pkgs)
        ];

        launchd.agents.nix-gc = {
          enable = true;
          config = {
            ProgramArguments = [
              "${nixPackage}/bin/nix-collect-garbage"
            ]
            ++ lib.optional (cfg.options != null) cfg.options;
            StartCalendarInterval = lib.hm.darwin.mkCalendarInterval (lib.elemAt cfg.dates 0);
          };
        };
      })
    ]
  );
}
