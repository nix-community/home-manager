{
  pkgs,
  lib,
  config,
  podman-lib,
  ...
}:

let
  awk = lib.getExe pkgs.gawk;
in
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

      # Print names and IDs of the resources, deliminated by comma
      # The names are matched against the resource manifest, and the IDs are used for deletion
      # Exception being the volumes, which use the names as their IDs
      [[ $resourceType = "container" ]] && formatString="{{.Names}},{{.ID}}"
      [[ $resourceType = "image" ]] && formatString="{{.Repository}},{{.ID}}"
      [[ $resourceType = "network" ]] && formatString="{{.Name}},{{.ID}}"
      [[ $resourceType = "volume" ]] && formatString="{{.Name}},{{.Name}}"

      local listOutput=$(${config.services.podman.package}/bin/podman $resourceType ls $extraListCommands --filter 'label=nix.home-manager.managed=true' --format "$formatString")

      # If $listOutput is empty, the arrays now do not have one empty string
      podmanResources=()
      podmanResourceIds=()
      if [ -n "$listOutput" ]; then
        readarray -t podmanResources < <(${awk} -F "," '{print $1}' <<< "$listOutput")
        readarray -t podmanResourceIds < <(${awk} -F "," '{print $2}' <<< "$listOutput")
      fi

      if [ ''${#podmanResources[@]} -eq 0 ]; then
        VERBOSE_ENABLED && echo "No ''${resourceType}s available to process." || true
      else
        for i in "''${!podmanResources[@]}"; do
          resource="''${podmanResources[$i]}"
          id="''${podmanResourceIds[$i]}"
          if ! isResourceInManifest "$resource"; then
            removeResource "$resourceType" "$resource" "$id"
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
      local id="$3"
      echo "Removing orphaned $resourceType: $resource with ID $id"
      commands=()
      case "$resourceType" in
        "container")
          commands+=("${config.services.podman.package}/bin/podman $resourceType stop $id")
          commands+=("${config.services.podman.package}/bin/podman $resourceType rm -f $id")
          ;;
        "image" | "network" | "volume")
          commands+=("${config.services.podman.package}/bin/podman $resourceType rm $id")
          ;;
      esac
      for command in "''${commands[@]}"; do
        command=$(echo $command | tr -d ';&|`')
        DRYRUN_ENABLED && echo "Would run: $command" && continue || true
        VERBOSE_ENABLED && echo "Running: $command" || true
        if ! eval "$command"; then
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
