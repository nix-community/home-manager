{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.services.secret-service;
in
{
  meta.maintainers = [ lib.maintainers.zebreus ];

  options = {
    services.secret-service = {
      enable = lib.mkEnableOption ''
        Enable managing secrets in the D-Bus secret service.
      '';

      secrets = lib.mkOption {
        default = [ ];
        description = ''
          List of secrets
        '';
        type = lib.types.listOf (
          lib.types.submodule (
            { lib, name, ... }:
            {
              options = {
                label = lib.mkOption {
                  type = lib.types.str;
                  default = name;
                  description = ''
                    The label of this secret. Will be displayed to the user.
                  '';
                };
                secretCommand = lib.mkOption {
                  type = lib.types.str;
                  example = "cat /run/agenix/important_secret.txt";
                  description = ''
                    The command to run to get the secret.

                    This command will get run once on every session start and the result will be
                    stored in the secret service. The command will be written into the Nix store
                    and is world-readable so make sure to not include any secrets in the command.
                  '';
                };
                attributes = lib.mkOption {
                  type = lib.types.attrsOf lib.types.str;
                  default = { };
                  description = ''
                    Attributes for the secret.
                  '';
                };
              };
            }
          )
        );
      };
    };

  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.secret-service" pkgs lib.platforms.linux)
    ];
    systemd.user = {
      startServices = lib.mkDefault "sd-switch";
      services.manage-secret-service-secrets =
        let
          storeSecretCommands = lib.concatStringsSep "\n" (
            map (
              {
                label,
                secretCommand,
                attributes,
              }:
              let
                attributesToString =
                  attrs:
                  lib.concatStringsSep " " (
                    lib.mapAttrsToList (name: value: "${lib.escapeShellArg name} ${lib.escapeShellArg value}") attrs
                  );
              in
              ''
                # shellcheck disable=all
                ${secretCommand} | sed -z '$ s/\\n$//' | storeManagedSecret ${lib.escapeShellArg label} ${attributesToString attributes}
              ''
            ) cfg.secrets
          );

          sharedFunctions = builtins.readFile ./helpers.bash;

          runtimeInputs = with pkgs; [
            coreutils
            dbus
            gnused
            gnugrep
            libsecret
          ];

          startScript = pkgs.writeShellApplication {
            inherit runtimeInputs;
            name = "updateSecrets";
            text = ''
              ${sharedFunctions}

              waitForUnlock || exit 1

              set -e
              removeManagedSecrets
              ${storeSecretCommands}
            '';
          };

          stopScript = pkgs.writeShellApplication {
            inherit runtimeInputs;
            name = "removeSecrets";
            text = ''
              ${sharedFunctions}

              if ! checkUnlock ; then
                echo "Collection is locked, skipping secret removal"
                exit 0
              fi

              set -e
              removeManagedSecrets
            '';
          };
        in
        {
          Unit = {
            Description = "insert secrets into the secret service";
            After = [
              "default.target"
              "dbus.service"
            ];
          };

          Service = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${lib.getExe startScript}";
            ExecStop = "${lib.getExe stopScript}";
            Restart = "on-failure";
            RestartSec = 30;
            TimeoutStopSec = 30;
            # The start script blocks until the secret service is unlocked
            TimeoutStartSec = "infinity";
            # Restart should be fine, as the stop script is not dependent on the configuration for now
            X-SwitchMethod = "restart";
          };

          Install = {
            WantedBy = [ "default.target" ];
          };
        };
    };
  };
}
