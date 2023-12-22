{ config, lib, pkgs, ... }:

with lib;

let
  # Function to build a single Podman quadlet, outputting its systemd unit files
  buildPodmanQuadlet = quadlet: pkgs.stdenv.mkDerivation {
    name = "home-${quadlet.unitType}-${quadlet.serviceName}";

    buildInputs = [ pkgs.podman ];

    src = pkgs.runCommandNoCC "dummy-src" {} ''
      mkdir $out
    '';

    buildPhase = ''
      # Directory for the quadlet file
      mkdir -p $out/quadlets
      # Directory for systemd unit files
      mkdir -p $out/units

      # Write the quadlet file
      echo -n "${quadlet.source}" > $out/quadlets/${quadlet.serviceName}.${quadlet.unitType}

      # Generate systemd unit file/s from the quadlet file
      export QUADLET_UNIT_DIRS=$out/quadlets
      ${pkgs.podman}/lib/systemd/user-generators/podman-user-generator $out/units
    '';
  };

  # Apply the buildPodmanQuadlet function to each quadlet
  builtUnits = map buildPodmanQuadlet config.internal.podman-quadlet-definitions;

  # Recursive function to build a map of all file paths with prefixes
  accumulateUnitFiles = prefix: path: let
    entries = builtins.readDir path;
    processEntry = name: type:
      let
        newPath = "${path}/${name}";
        newPrefix = prefix + (if prefix == "" then "" else "/") + name;
      in
        if type == "directory" then accumulateUnitFiles newPrefix newPath
        else [{ key = newPrefix; value = newPath; }];
  in flatten (map (name: processEntry name (getAttr name entries)) (attrNames entries));

  allUnitFiles = concatMap (builtUnit: accumulateUnitFiles "" "${builtUnit}/units") builtUnits;

  # we're doing this because the home-manager recursive file linking implementation can't 
  # merge from multiple sources. so we link each file explicitly, which is fine for all unique files
  generateHomeLinks = map (unitFile: {
    name = ".config/systemd/user/${unitFile.key}";
    value = { source = unitFile.value; };
  }) allUnitFiles;

in {
  imports = [
    ./options.nix
  ];

  config = {
    home.file = listToAttrs generateHomeLinks;
  };
}
