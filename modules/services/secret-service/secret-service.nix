{ pkgs, lib, config, ... }:
with lib;
let cfg = config.services.secret-service;
in {
  meta.maintainers = [ maintainers.zebreus ];

  options = {
    services.secret-service = {
      enable = mkEnableOption ''
        Enable managing passwords in the dbus secret service.
      '';

      secrets = mkOption {
        default = [ ];
        description = ''
          List of secrets
        '';
        type = types.listOf (types.submodule ({ lib, name, ... }:
          with lib; {
            options = {
              label = mkOption {
                type = types.str;
                default = name;
                description = ''
                  The label of this password. Will be displayed to the user.
                '';
              };
              secretCommand = mkOption {
                type = types.str;
                default = "cat /run/agenix/important_password.txt";
                description = ''
                  The command to run to get the secrect. The command will get run once on every session start and the result will be stored in the secret service.
                '';
              };
              attributes = mkOption {
                type = types.attrsOf types.str;
                default = { };
                description = ''
                  Attributes for the secret.
                '';
              };
            };
          }));
      };
    };

  };

  config = lib.mkIf cfg.enable {
    systemd.user = {
      startServices = mkDefault "sd-switch";
      services.manage-secret-service-passwords =
        let
          storeSecretCommands = lib.concatStringsSep "\n" (builtins.map
            ({ label, secretCommand, attributes }:
              let
                attributesToString = attrs:
                  lib.concatStringsSep " "
                    (lib.mapAttrsToList (name: value: "'${name}' '${value}'")
                      attrs);
              in
              ''
                # shellcheck disable=all
                ${secretCommand} | sed -z '$ s/\\n$//' | storeManagedSecret '${label}' ${
                  attributesToString attributes
                }
              '')
            cfg.secrets);

          sharedFunctions = builtins.readFile ./helpers.bash;

          startScript = pkgs.writeShellApplication {
            name = "updatePasswords";
            runtimeInputs = with pkgs; [
              coreutils
              dbus
              gnused
              gnugrep
              libsecret
            ];
            text = ''
              ${sharedFunctions}

              waitForUnlock || exit 1

              set -e
              removeManagedSecrets
              ${storeSecretCommands}
            '';
          };

          stopScript = pkgs.writeShellApplication {
            name = "removePasswords";
            runtimeInputs = with pkgs; [
              coreutils
              dbus
              gnused
              gnugrep
              libsecret
            ];
            text = ''
              ${sharedFunctions}

              checkUnlock || exit 1

              set -e
              removeManagedSecrets
            '';
          };
        in
        {
          Unit = {
            Description = "insert passwords into the secret service";
            After = [ "default.target" "dbus.service" ];
          };

          Service = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${lib.getExe startScript}";
            ExecStop = "${lib.getExe stopScript}";
            Restart = "on-failure";
            RestartSec = 30;
            TimeoutStopSec = 30;
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
