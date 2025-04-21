{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.podman;

  podman-lib = import ./podman-lib.nix { inherit pkgs lib config; };
  activation = import ./activation.nix { inherit config podman-lib; };

  activationCleanupScript = activation.cleanup;

  # derivation to build a single Podman quadlet, outputting its systemd unit files
  buildPodmanQuadlet =
    quadlet:
    pkgs.stdenv.mkDerivation {
      name = "home-${quadlet.resourceType}-${quadlet.serviceName}";

      buildInputs = [ cfg.package ] ++ quadlet.dependencies;

      unpackPhase = ''
        mkdir -p $out/quadlets
        ${lib.concatStringsSep "\n" (
          map (
            v:
            "echo 'linking ${v.quadletData.serviceName}.${v.quadletData.resourceType}'; ln -s ${v.out}/quadlets/${v.quadletData.serviceName}.${v.quadletData.resourceType} $out/quadlets"
          ) quadlet.dependencies
        )}
      '';

      installPhase = ''
        # Directory for systemd unit files
        mkdir -p $out/units

        # Write the quadlet file
        echo -n "${quadlet.source}" > $out/quadlets/${quadlet.serviceName}.${quadlet.resourceType}

        # Generate systemd unit file/s from the quadlet file
        export QUADLET_UNIT_DIRS=$out/quadlets
        ${cfg.package}/lib/systemd/user-generators/podman-user-generator $out/units
      '';

      passthru = {
        outPath = lib.self.out;
        quadletData = quadlet;
      };
    };

  builtQuadlets = map buildPodmanQuadlet cfg.internal.quadletDefinitions;

  accumulateUnitFiles =
    prefix: path: quadlet:
    let
      entries = builtins.readDir path;
      processEntry =
        name: type:
        let
          newPath = "${path}/${name}";
          newPrefix = prefix + (if prefix == "" then "" else "/") + name;
        in
        if type == "directory" then
          accumulateUnitFiles newPrefix newPath quadlet
        else
          [
            {
              key = newPrefix;
              value = {
                path = newPath;
                parentQuadlet = quadlet;
              };
            }
          ];
    in
    lib.flatten (map (name: processEntry name (lib.getAttr name entries)) (lib.attrNames entries));

  allUnitFiles = lib.concatMap (
    builtQuadlet: accumulateUnitFiles "" "${builtQuadlet.outPath}/units" builtQuadlet.quadletData
  ) builtQuadlets;

  # we're doing this because the home-manager recursive file linking implementation can't
  # merge from multiple sources. so we link each file explicitly, which is fine for all unique files
  generateSystemdFileLinks =
    files:
    lib.listToAttrs (
      map (unitFile: {
        name = "${config.xdg.configHome}/systemd/user/${unitFile.key}";
        value = {
          source = unitFile.value.path;
        };
      }) files
    );

in
{
  imports = [ ./options.nix ];

  config = lib.mkIf cfg.enable {
    home.file = generateSystemdFileLinks allUnitFiles;

    # if the length of builtQuadlets is 0, then we don't need register the activation script
    home.activation.podmanQuadletCleanup = lib.mkIf (lib.length builtQuadlets >= 1) (
      lib.hm.dag.entryAfter [ "reloadSystemd" ] activationCleanupScript
    );

    services.podman.internal.builtQuadlets = lib.listToAttrs (
      map (pkg: {
        name =
          (lib.removePrefix "podman-" pkg.passthru.quadletData.serviceName)
          + "."
          + pkg.passthru.quadletData.resourceType;
        value = pkg;
      }) builtQuadlets
    );
  };
}
