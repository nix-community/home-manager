{
  config,
  lib,
  options,
  pkgs,
  ...
}:

let
  cfg = config.services.home-manager.autoUpgrade;

  homeManagerPackage = config.programs.home-manager.package;

  preSwitchCommandsStateVersion = lib.hm.deprecations.mkStateVersionOptionDefault {
    inherit (config.home) stateVersion;
    inherit config options;
    since = "26.05";
    optionPath = [
      "services"
      "home-manager"
      "autoUpgrade"
      "preSwitchCommands"
    ];
    legacy.value = [ "nix flake update" ];
    current.value = [ ];
    deferWarningToConfig = true;
    shouldWarn = { optionUsesDefaultPriority, ... }: cfg.useFlake && optionUsesDefaultPriority;
  };

  hmExtraArgs = lib.escapeShellArgs cfg.flags;

  hasPreSwitchCommands = cfg.preSwitchCommands != [ ];

  preSwitchScript = lib.optionalString hasPreSwitchCommands (
    lib.concatStringsSep "\n" (
      [
        ''echo "Running pre-switch commands"''
        "set -o xtrace"
      ]
      ++ cfg.preSwitchCommands
    )
  );

  autoUpgradeApp = pkgs.writeShellApplication {
    name = "home-manager-auto-upgrade";

    runtimeInputs = with pkgs; [
      homeManagerPackage
      nix
    ];

    text =
      if cfg.useFlake then
        ''
          set -euo pipefail

          if [[ ! -f "$FLAKE_DIR/flake.nix" ]]; then
            echo "No flake.nix found in $FLAKE_DIR." >&2
            exit 1
          fi

          echo "Changing to flake directory $FLAKE_DIR"
          cd "$FLAKE_DIR"

          ${preSwitchScript}

          echo "Upgrade Home Manager"
          home-manager switch --flake . ${hmExtraArgs}
        ''
      else
        ''
          set -euo pipefail

          echo "Update Nix channels"
          nix-channel --update

          ${preSwitchScript}

          echo "Upgrade Home Manager"
          home-manager switch ${hmExtraArgs}
        '';
  };
in
{
  meta.maintainers = [ lib.hm.maintainers.soracat ];

  options = {
    services.home-manager.autoUpgrade = {
      enable = lib.mkEnableOption ''
        the Home Manager upgrade service that periodically updates your Nix
        configuration by running `home-manager switch`
      '';

      frequency = lib.mkOption {
        type = lib.types.str;
        example = "weekly";
        description = ''
          The interval at which the Home Manager auto upgrade is run.
          This value is passed to the systemd timer configuration
          as the `OnCalendar` option.
          The format is described in {manpage}`systemd.time(7)`.
        '';
      };

      useFlake = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to use flake-based Home Manager configuration.

          Flake URI uses FQDN, long, and short hostnames, and you must configure the corresponding user@host key in `homeConfigurations`. For example: user@hostname or user@host.example.com.

          Also check `services.home-manager.autoUpgrade.flakeDir` option.
        '';
      };

      flakeDir = lib.mkOption {
        type = lib.types.str;
        default = "${config.xdg.configHome}/home-manager";
        defaultText = lib.literalExpression ''"''${config.xdg.configHome}/home-manager"'';
        example = "/home/user/dotfiles";
        description = ''
          Directory containing flake.nix.
          Also check `services.home-manager.autoUpgrade.useFlake` option.
        '';
      };

      flags = lib.mkOption {
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
        defaultText = lib.literalExpression ''
          if lib.versionAtLeast config.home.stateVersion "26.05"
             || !config.services.home-manager.autoUpgrade.useFlake
          then
            [ ]
          else
            [ "nix flake update" ]
        '';
        example = lib.literalExpression ''
          [
            "''${pkgs.gitMinimal}/bin/git pull"
            "nix flake update"
          ]
        '';
        description = ''
          Shell commands executed before `home-manager switch`.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = lib.optional preSwitchCommandsStateVersion.shouldWarn preSwitchCommandsStateVersion.warning;

    assertions = [
      (lib.hm.assertions.assertPlatform "services.home-manager.autoUpgrade" pkgs lib.platforms.linux)
    ];

    services.home-manager.autoUpgrade.preSwitchCommands = lib.mkIf cfg.useFlake (
      lib.mkOptionDefault preSwitchCommandsStateVersion.effectiveDefault
    );

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
