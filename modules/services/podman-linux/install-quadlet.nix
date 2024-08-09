{ config, lib, pkgs, ... }:

with lib;

let
  quadletActivationCleanupScript = ''
    resourceManifest=()
    # Define VERBOSE_ENABLED as a function
    VERBOSE_ENABLED() {
      if [[ -n "''${VERBOSE:-}" ]]; then
        return 0
      else
        return 1
      fi
    }

    # Function to fill resourceManifest from the manifest file
    function loadManifest {
      local manifestFile="$1"
      VERBOSE_ENABLED && echo "Loading manifest from $manifestFile..."
      IFS=$'\n' read -r -d "" -a resourceManifest <<< "$(cat "$manifestFile")" || true
    }

    function isResourceInManifest {
      local resource="$1"
      for manifestEntry in "''${resourceManifest[@]}"; do
        if [ "$resource" = "$manifestEntry" ]; then
          return 0  # Resource found in manifest
        fi
      done
      return 1  # Resource not found in manifest
    }

    function removeContainer {
      echo "Removing orphaned container: $1"
      if [[ -n "''${DRY_RUN:-}" ]]; then
        echo "Would run podman stop $1"
        echo "Would run podman $resourceType rm -f $1"
      else
        ${config.services.podman.package}/bin/podman stop "$1"
        ${config.services.podman.package}/bin/podman $resourceType rm -f "$1"
      fi
    }

    function removeNetwork {
      echo "Removing orphaned network: $1"
      if [[ -n "''${DRY_RUN:-}" ]]; then
        echo "Would run podman network rm $1"
      else
        if ! ${config.services.podman.package}/bin/podman network rm "$1"; then
          echo "Failed to remove network $1. Is it still in use by a container?"
          return 1
        fi
      fi
    }

    function cleanup {
      local resourceType=$1
      local manifestFile="${config.xdg.configHome}/podman/$2"
      local extraListCommands="''${3:-}"
      [[ $resourceType = "container" ]] && extraListCommands+=" -a"

      VERBOSE_ENABLED && echo "Cleaning up ''${resourceType}s not in manifest..."

      loadManifest "$manifestFile"

      formatString="{{.Name}}"
      [[ $resourceType = "container" ]] && formatString="{{.Names}}"

      # Capture the output of the podman command to a variable
      local listOutput=$(${config.services.podman.package}/bin/podman $resourceType ls $extraListCommands --filter 'label=nix.home-manager.managed=true' --format "$formatString")

      IFS=$'\n' read -r -d "" -a podmanResources <<< "$listOutput" || true

      # Check if the array is populated and iterate over it
      if [ ''${#resourceManifest[@]} -eq 0 ]; then
        VERBOSE_ENABLED && echo "No ''${resourceType}s available to process."
      else
        for resource in "''${podmanResources[@]}"; do
            if ! isResourceInManifest "$resource"; then

              [[ $resourceType = "container" ]] && removeContainer "$resource"
              [[ $resourceType = "network" ]] && removeNetwork "$resource"

            else
              if VERBOSE_ENABLED; then
                echo "Keeping managed $resourceType: $resource"
              fi
            fi
          done
      fi
    }

    # Cleanup containers
    cleanup "container" "containers.manifest"

    # Cleanup networks
    cleanup "network" "networks.manifest"
  '';

  # derivation to build a single Podman quadlet, outputting its systemd unit files
  buildPodmanQuadlet = quadlet: pkgs.stdenv.mkDerivation {
    name = "home-${quadlet.unitType}-${quadlet.serviceName}";

    buildInputs = [ config.services.podman.package ];

    dontUnpack = true;

    buildPhase = ''
      mkdir $out
      # Directory for the quadlet file
      mkdir -p $out/quadlets
      # Directory for systemd unit files
      mkdir -p $out/units

      # Write the quadlet file
      echo -n "${quadlet.source}" > $out/quadlets/${quadlet.serviceName}.${quadlet.unitType}

      # Generate systemd unit file/s from the quadlet file
      export QUADLET_UNIT_DIRS=$out/quadlets
      ${config.services.podman.package}/lib/systemd/user-generators/podman-user-generator $out/units
    '';

    passthru = {
      outPath = self.out;
      quadletData = quadlet;
    };
  };

  # Create a derivation for each quadlet spec
  builtQuadlets = map buildPodmanQuadlet config.internal.podman-quadlet-definitions;

  accumulateUnitFiles = prefix: path: quadlet: let
    entries = builtins.readDir path;
    processEntry = name: type:
      let
        newPath = "${path}/${name}";
        newPrefix = prefix + (if prefix == "" then "" else "/") + name;
      in
        if type == "directory" then accumulateUnitFiles newPrefix newPath quadlet
        else [{
          key = newPrefix;
          value = { path = newPath; parentQuadlet = quadlet; };
        }];
  in flatten (map (name: processEntry name (getAttr name entries)) (attrNames entries));

  allUnitFiles = concatMap (builtQuadlet: accumulateUnitFiles "" "${builtQuadlet.outPath}/units" builtQuadlet.quadletData ) builtQuadlets;

  # we're doing this because the home-manager recursive file linking implementation can't
  # merge from multiple sources. so we link each file explicitly, which is fine for all unique files
  generateSystemdFileLinks = files: listToAttrs (map (unitFile: {
    name = "${config.xdg.configHome}/systemd/user/${unitFile.key}";
    value = {
      source = unitFile.value.path;
    };
  }) files);

in {
  imports = [
    ./options.nix
  ];

  config = {
    home.file = generateSystemdFileLinks allUnitFiles;

    # if the length of builtQuadlets is 0, then we don't need register the activation script
    home.activation.podmanQuadletCleanup = lib.mkIf (lib.length builtQuadlets >= 1) (lib.hm.dag.entryAfter ["reloadSystemd"] quadletActivationCleanupScript);
  };
}
