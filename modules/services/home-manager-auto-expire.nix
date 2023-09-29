{ config, lib, pkgs, ... }:

let

  cfg = config.services.home-manager.autoExpire;

  homeManagerPackage = pkgs.callPackage ../../home-manager {
    path = config.programs.home-manager.path;
  };

in {
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
          Remove generations older than TIMESTAMP where TIMESTAMP is
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
          The format is described in
          {manpage}`systemd.time(7)`.
        '';
      };

      store = {
        cleanup = lib.mkEnableOption ''
          to cleanup Nix store when the Home Manager expire service runs.

          It will use `nix-collect-garbage` to cleanup the store,
          removing all unreachable store objects from the current user
          (i.e.: not only the expired Home Manager generations).

          This may not be what you want, this is why this option is disabled
          by default.'';

        options = lib.mkOption {
          type = lib.types.str;
          description = ''
            Options given to `nix-collection-garbage` when the service runs.
          '';
          default = "";
          example = "--delete-older-than 30d";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.home-manager.autoExpire" pkgs
        lib.platforms.linux)
    ];

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

        Service.ExecStart = toString
          (pkgs.writeShellScript "home-manager-auto-expire" (''
            echo "Expire old Home Manager generations"
            ${homeManagerPackage}/bin/home-manager expire-generations '${cfg.timestamp}'
          '' + lib.optionalString cfg.store.cleanup ''
            echo "Clean-up Nix store"
            ${pkgs.nix}/bin/nix-collect-garbage ${cfg.store.options}
          ''));
      };
    };
  };
}
