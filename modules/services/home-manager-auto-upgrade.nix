{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.home-manager.autoUpgrade;

  homeManagerPackage = config.programs.home-manager.package;

  hmExtraArgs = lib.escapeShellArgs cfg.extraArgs;

  preSwitchScript = lib.concatStringsSep "\n" (
    map (cmd: ''
      echo "+ ${cmd}"
      ${cmd}
    '') cfg.preSwitchCommands
  );

  autoUpgradeApp = pkgs.writeShellApplication {
    name = "home-manager-auto-upgrade";

    runtimeInputs = with pkgs; [
      homeManagerPackage
      nix
      git
    ];

    text =
      if cfg.useFlake then
        ''
          set -euo pipefail

          if [[ -z "''${FLAKE_DIR:-}" ]]; then
            echo "FLAKE_DIR is not set" >&2
            exit 1
          fi

          if [[ ! -f "$FLAKE_DIR/flake.nix" ]]; then
            echo "No flake.nix found in $FLAKE_DIR." >&2
            exit 1
          fi

          echo "Changing to flake directory $FLAKE_DIR"
          cd "$FLAKE_DIR"

          echo "Running pre-switch commands"
          ${preSwitchScript}

          echo "Upgrade Home Manager"
          home-manager switch --flake . ${hmExtraArgs}
        ''
      else
        ''
          set -euo pipefail

          echo "Update Nix channels"
          nix-channel --update

          echo "Running pre-switch commands"
          ${preSwitchScript}

          echo "Upgrade Home Manager"
          home-manager switch ${hmExtraArgs}
        '';
  };
in
{
  meta.maintainers = [ lib.maintainers.pinage404 ];

  options = {
    services.home-manager.autoUpgrade = {
      enable = lib.mkEnableOption ''
        the Home Manager upgrade service that periodically updates your Nix
        configuration before running `home-manager switch`
      '';

      frequency = lib.mkOption {
        type = lib.types.str;
        example = "weekly";
        description = ''
          The interval at which the Home Manager auto upgrade is run.
          This value is passed to the systemd timer configuration
          as the `OnCalendar` option.
          The format is described in systemd.time(7).
        '';
      };

      useFlake = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to use flake-based Home Manager configuration.
        '';
      };

      flakeDir = lib.mkOption {
        type = lib.types.str;
        default = "${config.xdg.configHome}/home-manager";
        defaultText = lib.literalExpression ''"''${config.xdg.configHome}/home-manager"'';
        example = "/home/user/dotfiles";
        description = ''
          Directory containing flake.nix.
        '';
      };

      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [
          "--impure"
          "-b"
          "hmbak"
        ];
        description = ''
          Extra arguments passed to `home-manager switch`.
        '';
      };

      preSwitchCommands = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [
          "nix flake update"
        ];
        description = ''
          Shell commands executed before `home-manager switch`.
          Each entry is executed as a separate command.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.home-manager.autoUpgrade" pkgs lib.platforms.linux)
    ];

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
        Unit = {
          Description = "Home Manager upgrade";
          X-SwitchMethod = "keep-old";
        };

        Service = {
          ExecStart = "${autoUpgradeApp}/bin/home-manager-auto-upgrade";

          Environment = lib.mkIf cfg.useFlake [
            "FLAKE_DIR=${cfg.flakeDir}"
          ];
        };
      };
    };
  };
}
