{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.home-manager.autoUpgrade;

  homeManagerPackage = config.programs.home-manager.package;

  hmExtraArgs = lib.escapeShellArgs cfg.flags;

  legacyPreSwitchCommands = lib.warn ''
    services.home-manager.autoUpgrade:
    Implicit `nix flake update` before `home-manager switch` is deprecated.
    Please set `services.home-manager.autoUpgrade.preSwitchCommands`
    explicitly.
  '' [ "nix flake update" ];

  # null = legacy behavior
  # []   = run nothing
  preSwitchCommands =
    if cfg.useFlake && cfg.preSwitchCommands == null then
      legacyPreSwitchCommands
    else if cfg.preSwitchCommands == null then
      [ ]
    else
      cfg.preSwitchCommands;

  hasPreSwitchCommands = preSwitchCommands != [ ];

  preSwitchScript = lib.optionalString hasPreSwitchCommands (
    lib.concatStringsSep "\n" (
      [
        ''echo "Running pre-switch commands"''
      ]
      ++ map (cmd: ''
        echo "+ ${cmd}"
        ${cmd}
      '') preSwitchCommands
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
        configuration before running `home-manager switch`
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
        type = lib.types.nullOr (lib.types.listOf lib.types.str);
        default = null;
        example = lib.literalExpression ''
          [
            "nix flake update"
            "''${pkgs.git}/bin/git pull"
          ]
        '';
        description = ''
          Shell commands executed before `home-manager switch`.

          - null: use legacy behavior (deprecated)
          - []: run no pre-switch commands
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
