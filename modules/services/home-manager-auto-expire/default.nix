{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.services.home-manager.autoExpire;

  homeManagerPackage = pkgs.callPackage ../../../home-manager {
    path = config.programs.home-manager.path;
  };

  script = pkgs.writeShellScript "home-manager-auto-expire" (
    ''
      echo "Expire old Home Manager generations"
      ${homeManagerPackage}/bin/home-manager expire-generations '${cfg.timestamp}'
    ''
    + lib.optionalString cfg.store.cleanup ''
      echo "Clean-up Nix store"
      ${pkgs.nix}/bin/nix-collect-garbage ${cfg.store.options}
    ''
  );

in
{
  meta.maintainers = [ lib.maintainers.thiagokokada ];

  options = {
    services.home-manager.autoExpire = {
      enable = lib.mkEnableOption ''
        the Home Manager expire service that periodically expire your
        old Home Manager generations'';

      timestamp = lib.mkOption {
        type = lib.types.str;
        default = "-30 days";
        example = "-7 days";
        description = ''
          Remove generations older than `TIMESTAMP` where `TIMESTAMP` is
          interpreted as in the -d argument of the date tool.
        '';
      };

      frequency = lib.mkOption {
        type = lib.types.str;
        default = "monthly";
        example = "weekly";
        description = ''
          The interval at which the Home Manager auto expire is run.

          This value is passed to the systemd timer configuration
          as the `OnCalendar` option.

          The format is described in {manpage}`systemd.time(7)`.

          ${lib.hm.darwin.intervalDocumentation}
        '';
      };

      store = {
        cleanup = lib.mkEnableOption ''
          to cleanup Nix store when the Home Manager expire service runs.

          It will use `nix-collect-garbage` to cleanup the store,
          removing all unreachable store objects from the current user
          (i.e.: not only the expired Home Manager generations).

          This may not be what you want, this is why this option is disabled
          by default'';

        options = lib.mkOption {
          type = lib.types.str;
          description = ''
            Options given to `nix-collect-garbage` when the service runs.
          '';
          default = "";
          example = "--delete-older-than 30d";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf pkgs.stdenv.isLinux {
        systemd.user = {
          timers.home-manager-auto-expire = {
            Unit.Description = "Home Manager expire generations timer";

            Install.WantedBy = [ "timers.target" ];

            Timer = {
              OnCalendar = cfg.frequency;
              Unit = "home-manager-auto-expire.service";
              Persistent = true;
            };
          };

          services.home-manager-auto-expire = {
            Unit.Description = "Home Manager expire generations";

            Service.ExecStart = toString script;
          };
        };
      })

      (lib.mkIf pkgs.stdenv.isDarwin {
        assertions = [
          (lib.hm.darwin.assertInterval "services.home-manager.autoExpire.frequency" cfg.frequency pkgs)
        ];

        launchd.agents.home-manager-auto-expire = {
          enable = true;
          config = {
            ProgramArguments = [ (toString script) ];
            ProcessType = "Background";
            StartCalendarInterval = lib.hm.darwin.mkCalendarInterval cfg.frequency;
            StandardOutPath = "${config.home.homeDirectory}/Library/Logs/home-manager-auto-expire/launchd-stdout.log";
            StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/home-manager-auto-expire/launchd-stderr.log";
          };
        };
      })
    ]
  );
}
