{ config, lib, pkgs, ... }:

let

  cfg = config.services.home-manager.autoUpgrade;

  homeManagerPackage = pkgs.callPackage ../../home-manager {
    path = config.programs.home-manager.path;
  };

in {
  meta.maintainers =
    [ lib.hm.maintainers.pinage404 lib.hm.maintainers.shikanime ];

  options = {
    services.home-manager.autoUpgrade = {
      enable = lib.mkEnableOption ''
        the Home Manager upgrade service that periodically updates your Nix
        channels before running `home-manager switch`'';

      frequency = lib.mkOption {
        type = lib.types.str;
        example = "weekly";
        description = ''
          The interval at which the Home Manager auto upgrade is run.
          This value is passed to the systemd timer configuration
          as the `OnCalendar` option.
          The format is described in
          {manpage}`systemd.time(7)`.
        '';
      };

      flake = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "github:alice/dotfiles";
        description = lib.mdDoc ''
          The Flake URI of the home-manager configuration to build.
        '';
      };

      flags = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [
          "-I"
          "stuff=/home/alice/home-manager-stuff"
          "--option"
          "extra-binary-caches"
          "http://my-cache.example.org/"
        ];
        description = lib.mdDoc ''
          Any additional flags passed to {command}`home-manager`.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.home-manager.autoUpgrade" pkgs
        lib.platforms.linux)
    ];

    services.home-manager.autoUpgrade.flags =
      if cfg.flake != null then [ "--flake" cfg.flake ] else [ ];

    systemd.user = {
      timers.home-manager-auto-upgrade = {
        Unit.Description = "Home Manager upgrade timer";

        Install.WantedBy = [ "timers.target" ];

        Timer = {
          OnCalendar = cfg.frequency;
          Unit = "home-manager-auto-upgrade.service";
          Persistent = true;
        };
      };

      services.home-manager-auto-upgrade = {
        Unit.Description = "Home Manager upgrade";

        Service.ExecStart = toString
          (pkgs.writeShellScript "home-manager-auto-upgrade" ''
            echo "Update Nix's channels"
            ${pkgs.nix}/bin/nix-channel --update
            echo "Upgrade Home Manager"
            ${homeManagerPackage}/bin/home-manager switch ${
              lib.escapeShellArgs cfg.flags
            }
          '');
      };
    };
  };
}
