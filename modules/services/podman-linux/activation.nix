{ config, podman-lib, ... }:

{
  cleanup = ''
    PATH=$PATH:${podman-lib.newuidmapPaths}
    export VERBOSE=true

    DRYRUN_ENABLED() {
      return $([ -n "''${DRY_RUN:-}" ] && echo 0 || echo 1)
    }

    VERBOSE_ENABLED() {
      return $([ -n "''${VERBOSE:-}" ] && echo 0 || echo 1)
    }

    cleanup() {
      local resourceType=$1
      local manifestFile="${config.xdg.configHome}/podman/$2"
      local extraListCommands="''${3:-}"
      [[ $resourceType = "container" ]] && extraListCommands+=" -a"
      [[ $resourceType = "volume" ]] && extraListCommands+=" --filter label=nix.home-manager.preserve=false"

      [ ! -f "$manifestFile" ] && VERBOSE_ENABLED && echo "Manifest does not exist: $manifestFile" && return 0

      VERBOSE_ENABLED && echo "Cleaning up ''${resourceType}s not in manifest..." || true

      loadManifest "$manifestFile"

      formatString="{{.Name}}"
      [[ $resourceType = "container" ]] && formatString="{{.Names}}"
      [[ $resourceType = "image" ]] && formatString="{{.Repository}}"

      local listOutput=$(${config.services.podman.package}/bin/podman $resourceType ls $extraListCommands --filter 'label=nix.home-manager.managed=true' --format "$formatString")

      IFS=$'\n' read -r -d "" -a podmanResources <<< "$listOutput" || true

      if [ ''${#podmanResources[@]} -eq 0 ]; then
        VERBOSE_ENABLED && echo "No ''${resourceType}s available to process." || true
      else
        for resource in "''${podmanResources[@]}"; do
          if ! isResourceInManifest "$resource"; then
            removeResource "$resourceType" "$resource"
          else
            VERBOSE_ENABLED && echo "Keeping managed $resourceType: $resource" || true
          fi
        done
      fi
    }

    isResourceInManifest() {
      local resource="$1"
      for manifestEntry in "''${resourceManifest[@]}"; do
        if [ "$resource" = "$manifestEntry" ]; then
          return 0  # Resource found in manifest
        fi
      done
      return 1  # Resource not found in manifest
    }

    # Function to fill resourceManifest from the manifest file
    loadManifest() {
      local manifestFile="$1"
      VERBOSE_ENABLED && echo "Loading manifest from $manifestFile..." || true
      IFS=$'\n' read -r -d "" -a resourceManifest <<< "$(cat "$manifestFile")" || true
    }

    removeResource() {
      local resourceType="$1"
      local resource="$2"
      echo "Removing orphaned $resourceType: $resource"
      commands=()
      case "$resourceType" in
        "container")
          commands+=("${config.services.podman.package}/bin/podman $resourceType stop $resource")
          commands+=("${config.services.podman.package}/bin/podman $resourceType rm -f $resource")
          ;;
        "image" | "network" | "volume")
          commands+=("${config.services.podman.package}/bin/podman $resourceType rm $resource")
          ;;
      esac
      for command in "''${commands[@]}"; do
        command=$(echo $command | tr -d ';&|`')
        DRYRUN_ENABLED && echo "Would run: $command" && continue || true
        VERBOSE_ENABLED && echo "Running: $command" || true
        if [[ "$(eval "$command")" != *"$resource" ]]; then
          echo -e "\tCommand failed: ''${command}"
          [ "$resourceType" == "image" ] && resourceType="ancestor"
          usedByContainers=$(${config.services.podman.package}/bin/podman container ls -a --filter "$resourceType=$resource" --format "{{.Names}}")
          echo -e "\t$resource in use by containers: $usedByContainers"
        fi
      done
    }

    resourceManifest=()
    [[ "$@" == *"--verbose"* ]] && VERBOSE="true"
    [[ "$@" == *"--dry-run"* ]] && DRY_RUN="true"

    for type in "container" "image" "network" "volume"; do
      cleanup "$type" "''${type}s.manifest"
    done
  '';
}
