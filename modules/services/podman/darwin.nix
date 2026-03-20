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
    mkMerge
    nameValuePair
    optionalString
    types
    ;
  assertions = import ./assertions.nix { inherit lib; };

  cfg = config.services.podman;

  machineDefinitionType = types.submodule {
    options = {
      cpus = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
        example = 2;
        description = "Number of CPUs to allocate to the machine. If null, uses podman's default.";
      };

      diskSize = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
        example = 200;
        description = "Disk size in GB for the machine. If null, uses podman's default.";
      };

      image = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Bootable image to use for the machine. If null, uses podman's default.";
      };

      memory = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
        example = 8192;
        description = "Memory in MB to allocate to the machine. If null, uses podman's default.";
      };

      rootful = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = ''
          Whether to run the machine in rootful mode. If null, uses podman's default.
          Rootful mode runs containers as root inside the VM.
        '';
      };

      swap = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
        example = 2048;
        description = "Swap size in MB for the machine. If null, uses podman's default.";
      };

      timezone = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "UTC";
        description = "Timezone to set in the machine. If null, uses podman's default.";
      };

      username = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "user";
        description = "Username used in the machine image. If null, uses podman's default.";
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
        example = false;
        description = "Whether to automatically start this machine on login.";
      };

      watchdogInterval = mkOption {
        type = types.ints.positive;
        default = 30;
        example = 60;
        description = "Interval in seconds to check if the machine is running";
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

        The default machine will be named `podman-machine-default` and configured with podmans default values.
      '';
      readOnly = pkgs.stdenv.hostPlatform.isLinux;
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
            swap = 2048;
            timezone = "UTC";
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
                cpus = null;
                diskSize = null;
                image = null;
                memory = null;
                rootful = null;
                swap = null;
                timezone = null;
                username = null;
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
    mkIf cfg.enable (mkMerge [
      {
        assertions = [
          (assertions.assertPlatform "services.podman.useDefaultMachine" config pkgs lib.platforms.darwin)
          (assertions.assertPlatform "services.podman.machines" config pkgs lib.platforms.darwin)
        ];
      }

      (mkIf pkgs.stdenv.isDarwin {
        home.activation.podmanMachines =
          let
            mkMachineInitScript =
              name: machine:
              let
                # Automatically mount host's container config into the VM
                username = if isNull machine.username then "core" else machine.username;
                configVolume = "$HOME/.config/containers:/home/${username}/.config/containers";
                allVolumes = [ configVolume ] ++ machine.volumes;
              in
              ''
                if ! ${podmanCmd} machine list --format '{{.Name}}' 2>/dev/null | sed 's/\*$//' | grep -q '^${name}$'; then
                  echo "Creating podman machine: ${name}"
                  ${podmanCmd} machine init ${name} \
                    ${optionalString (machine.cpus != null) "--cpus ${toString machine.cpus}"} \
                    ${optionalString (machine.diskSize != null) "--disk-size ${toString machine.diskSize}"} \
                    ${optionalString (machine.image != null) "--image ${machine.image}"} \
                    ${optionalString (machine.memory != null) "--memory ${toString machine.memory}"} \
                    ${optionalString ((machine.rootful != null) && machine.rootful) "--rootful"} \
                    ${optionalString (machine.swap != null) "--swap ${toString machine.swap}"} \
                    ${optionalString (machine.timezone != null) "--timezone \"${machine.timezone}\""} \
                    ${optionalString (machine.username != null) "--username \"${machine.username}\""} \
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
      })
    ]);
}
