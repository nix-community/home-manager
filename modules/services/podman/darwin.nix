{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrNames
    concatStringsSep
    filterAttrs
    mapAttrs'
    mkIf
    mkOption
    nameValuePair
    optionalString
    types
    ;

  cfg = config.services.podman;

  machineDefinitionType = types.submodule {
    options = {
      cpus = mkOption {
        type = types.ints.positive;
        default = 4;
        example = 2;
        description = "Number of CPUs to allocate to the machine.";
      };

      memory = mkOption {
        type = types.ints.positive;
        default = 2048;
        example = 8192;
        description = "Memory in MB to allocate to the machine.";
      };

      diskSize = mkOption {
        type = types.ints.positive;
        default = 100;
        example = 200;
        description = "Disk size in GB for the machine.";
      };

      rootful = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to run the machine in rootful mode.
          Rootful mode runs containers as root inside the VM.
        '';
      };

      autoStart = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to automatically start this machine on login.";
      };

      watchdogInterval = mkOption {
        type = types.ints.positive;
        default = 30;
        example = 60;
        description = "Interval in seconds to check if the machine is running.";
      };
    };
  };

  mkWatchdogScript =
    name: machine:
    pkgs.writeShellScript "podman-machine-watchdog-${name}" ''
      set -euo pipefail

      MACHINE_NAME="${name}"
      INTERVAL=${toString machine.watchdogInterval}
      PODMAN="${lib.getExe cfg.package}"

      log() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
      }

      check_and_start() {
        local state
        state=$($PODMAN machine inspect "$MACHINE_NAME" --format '{{.State}}' 2>/dev/null || echo "unknown")

        case "$state" in
          running)
            return 0
            ;;
          stopped|unknown)
            log "Machine '$MACHINE_NAME' is starting..."
            if $PODMAN machine start "$MACHINE_NAME" 2>&1 | while IFS= read -r line; do log "$line"; done; then
              log "Machine '$MACHINE_NAME' started successfully"
              return 0
            else
              log "Failed to start machine '$MACHINE_NAME'"
              return 1
            fi
            ;;
          *)
            log "Machine '$MACHINE_NAME' is $state"
            return 1
            ;;
        esac
      }

      log "Starting watchdog for machine '$MACHINE_NAME' (check interval: ''${INTERVAL}s)"

      while true; do
        check_and_start || true
        sleep "$INTERVAL"
      done
    '';
in
{
  options.services.podman.darwin = {
    useDefaultMachine = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to create and use the default podman machine.

        The default machine will be named `podman-machine-default` and configured with:
        - 4 CPUs
        - 2048 MB RAM
        - 100 GB disk
        - Rootless mode
        - Auto-start enabled
      '';
    };

    machines = mkOption {
      type = types.attrsOf machineDefinitionType;
      default = { };
      description = "Declarative podman machine configurations.";
      example = lib.literalExpression ''
        {
          "dev-machine" = {
            cpus = 4;
            memory = 8192;
            diskSize = 100;
            rootful = false;
            autoStart = true;
            watchdogInterval = 30;
          };
          "testing" = {
            cpus = 2;
            memory = 4096;
            diskSize = 50;
            rootful = false;
            autoStart = false;
          };
        }
      '';
    };
  };

  config =
    let
      podmanCmd = lib.getExe cfg.package;
      allMachines =
        cfg.darwin.machines
        // (
          if cfg.darwin.useDefaultMachine then
            {
              "podman-machine-default" = {
                cpus = 4;
                memory = 2048;
                diskSize = 100;
                rootful = false;
                autoStart = true;
                watchdogInterval = 30;
              };
            }
          else
            { }
        );
      autoStartMachines = filterAttrs (_name: machine: machine.autoStart) allMachines;
    in
    mkIf (cfg.enable && pkgs.stdenv.isDarwin) {

      home.activation.podmanMachines =
        let
          mkMachineInitScript = name: machine: ''
            if ! ${podmanCmd} machine list --format '{{.Name}}' | grep '^${name}\*\?$'; then
              echo "Creating podman machine: ${name}"
              ${podmanCmd} machine init ${name} \
                --cpus ${toString machine.cpus} \
                --memory ${toString machine.memory} \
                --disk-size ${toString machine.diskSize} \
                ${optionalString machine.rootful "--rootful"}
            fi
          '';

          mkMachineCleanupScript = name: ''
            if ${podmanCmd} machine list --format '{{.Name}}' | grep '^${name}\*\?$'; then
              echo "Removing unmanaged podman machine: ${name}"
              ${podmanCmd} machine stop ${name} 2>/dev/null || true
              ${podmanCmd} machine rm -f ${name}
            fi
          '';
        in
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          PATH="${cfg.package}/bin:$PATH"

          ${concatStringsSep "\n" (lib.mapAttrsToList mkMachineInitScript allMachines)}

          MANAGED_MACHINES="${concatStringsSep " " (attrNames allMachines)}"
          EXISTING_MACHINES=$(${podmanCmd} machine list --format '{{.Name}}' 2>/dev/null || echo "")

          for machine in $EXISTING_MACHINES; do
            if [[ ! " $MANAGED_MACHINES " =~ " $machine " ]]; then
              ${mkMachineCleanupScript "$machine"}
            fi
          done
        '';

      launchd.agents = mapAttrs' (
        name: machine:
        nameValuePair "podman-machine-${name}" {
          enable = true;
          config = {
            ProgramArguments = [ "${mkWatchdogScript name machine}" ];
            KeepAlive = {
              Crashed = true;
              SuccessfulExit = false;
            };
            ProcessType = "Background";
            RunAtLoad = true;
          };
        }
      ) autoStartMachines;
    };
}
