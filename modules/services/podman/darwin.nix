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

      diskSize = mkOption {
        type = types.ints.positive;
        default = 100;
        example = 200;
        description = "Disk size in GB for the machine.";
      };

      image = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Bootable image to use for the machine. If null, uses podman's default.";
      };

      memory = mkOption {
        type = types.ints.positive;
        default = 2048;
        example = 8192;
        description = "Memory in MB to allocate to the machine.";
      };

      rootful = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to run the machine in rootful mode.
          Rootful mode runs containers as root inside the VM.
        '';
      };

      swap = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
        example = 2048;
        description = "Swap size in MB for the machine.";
      };

      timezone = mkOption {
        type = types.str;
        default = "local";
        example = "UTC";
        description = "Timezone to set in the machine.";
      };

      userModeNetworking = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to use user-mode networking, routing traffic through a host user-space process.
          This may be required for certain network configurations.
        '';
      };

      username = mkOption {
        type = types.str;
        default = "core";
        description = "Username used in the machine image.";
      };

      volumes = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [
          "/Users:/Users"
          "/private:/private"
          "/var/folders:/var/folders"
        ];
        description = ''
          Volumes to mount in the machine, specified as source:target pairs.
          If empty, podman will use its default volume mounts.
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
  options.services.podman = {
    useDefaultMachine = mkOption {
      type = types.bool;
      default = pkgs.stdenv.hostPlatform.isDarwin;
      description = ''
        Whether to create and use the default podman machine.

        The default machine will be named `podman-machine-default` and configured with:
        - 4 CPUs
        - 2048 MB RAM
        - 100 GB disk
        - Rootless mode
        - Auto-start enabled
        - No swap
        - Local timezone
        - Standard networking (not user-mode)
        - Default username (core)
        - Default volume mounts
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
            diskSize = 100;
            memory = 8192;
            rootful = false;
            swap = 2048;
            timezone = "UTC";
            userModeNetworking = false;
            volumes = [
              "/Users:/Users"
              "/private:/private"
            ];
            autoStart = true;
            watchdogInterval = 30;
          };
          "testing" = {
            cpus = 2;
            diskSize = 50;
            image = "ghcr.io/your-org/custom-image:latest";
            memory = 4096;
            rootful = false;
            username = "podman";
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
        cfg.machines
        // (
          if cfg.useDefaultMachine then
            {
              "podman-machine-default" = {
                cpus = 4;
                diskSize = 100;
                image = null;
                memory = 2048;
                rootful = false;
                swap = null;
                timezone = "local";
                userModeNetworking = false;
                username = "core";
                volumes = [ ];
                autoStart = true;
                watchdogInterval = 30;
              };
            }
          else
            { }
        );
      autoStartMachines = filterAttrs (_name: machine: machine.autoStart) allMachines;
    in
    mkIf (cfg.enable && pkgs.stdenv.hostPlatform.isDarwin) {
      assertions = [
        {
          assertion = pkgs.stdenv.hostPlatform.isDarwin;
          message = ''
            Podman Darwin-specific options are configured, but you are not on a Darwin (macOS) system.
            The following options are only available on macOS:
            - services.podman.machines
            - services.podman.useDefaultMachine

            Please remove these Darwin-specific configurations from your home-manager configuration.
          '';
        }
      ];

      home.activation.podmanMachines =
        let
          mkMachineInitScript =
            name: machine:
            let
              # Automatically mount host's container config into the VM
              configVolume = "$HOME/.config/containers:/home/${machine.username}/.config/containers";
              allVolumes = [ configVolume ] ++ machine.volumes;
            in
            ''
              if ! ${podmanCmd} machine list --format '{{.Name}}' 2>/dev/null | sed 's/\*$//' | grep -q '^${name}$'; then
                echo "Creating podman machine: ${name}"
                ${podmanCmd} machine init ${name} \
                  --cpus ${toString machine.cpus} \
                  --disk-size ${toString machine.diskSize} \
                  ${optionalString (machine.image != null) "--image ${machine.image}"} \
                  --memory ${toString machine.memory} \
                  ${optionalString machine.rootful "--rootful"} \
                  ${optionalString (machine.swap != null) "--swap ${toString machine.swap}"} \
                  --timezone "${machine.timezone}" \
                  ${optionalString machine.userModeNetworking "--user-mode-networking"} \
                  --username "${machine.username}" \
                  ${concatStringsSep " " (map (v: "--volume \"${v}\"") allVolumes)}
              fi
            '';

        in
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          PATH="${cfg.package}/bin:$PATH"

          ${concatStringsSep "\n" (lib.mapAttrsToList mkMachineInitScript allMachines)}

          MANAGED_MACHINES="${concatStringsSep " " (attrNames allMachines)}"
          EXISTING_MACHINES=$(${podmanCmd} machine list --format '{{.Name}}' 2>/dev/null | sed 's/\*$//' || echo "")

          for machine in $EXISTING_MACHINES; do
            if [[ ! " $MANAGED_MACHINES " =~ " $machine " ]]; then
              echo "Removing unmanaged podman machine: $machine"
              ${podmanCmd} machine stop "$machine" 2>/dev/null || true
              ${podmanCmd} machine rm -f "$machine"
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
