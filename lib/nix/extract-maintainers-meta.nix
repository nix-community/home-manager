# Extract maintainers from Home Manager modules using meta.maintainers
# This script evaluates all Home Manager modules and extracts the merged maintainer information
let
  flakeLock = builtins.fromJSON (builtins.readFile ../../flake.lock);
  nixpkgsNodeName = flakeLock.nodes.root.inputs.nixpkgs;
  nixpkgsLocked = flakeLock.nodes.${nixpkgsNodeName}.locked;

  pkgs = import (fetchTarball {
    url = "https://github.com/${nixpkgsLocked.owner}/${nixpkgsLocked.repo}/archive/${nixpkgsLocked.rev}.tar.gz";
    sha256 = nixpkgsLocked.narHash;
  }) { };
  lib = import ../../modules/lib/stdlib-extended.nix pkgs.lib;
  releaseInfo = pkgs.lib.importJSON ../../release.json;

  docsLib = import ../../docs {
    inherit lib pkgs;
    inherit (releaseInfo) release isReleaseBranch;
  };

  moduleMaintainersJson = builtins.fromJSON (builtins.readFile docsLib.jsonModuleMaintainers);
  maintainers = moduleMaintainersJson;

  # TODO: Find a better solution for extracting maintainers outside `modules`
  additionalFiles = [
    ../../docs/home-manager-manual.nix
  ];

  extractAdditionalMaintainers =
    files:
    lib.concatLists (
      map (
        file:
        let
          fileContent = import file;
          # Arguments expected by docs/home-manager-manual.nix.
          evaluated =
            if lib.isFunction fileContent then
              fileContent {
                inherit lib;
                inherit (pkgs)
                  callPackage
                  mdbook
                  python3
                  stdenv
                  ;
                revision = "unknown";
                home-manager-options = {
                  home-manager = { };
                  nixos = { };
                  nix-darwin = { };
                };
              }
            else
              fileContent;

          maintainersList = evaluated.meta.maintainers or [ ];
        in
        if lib.isList maintainersList then maintainersList else [ maintainersList ]
      ) files
    );

  additionalMaintainerObjects = extractAdditionalMaintainers additionalFiles;

  extractMaintainerObjects =
    maintainerData:
    lib.pipe maintainerData [
      lib.attrValues
      lib.concatLists
      lib.unique
    ];

  allMaintainerObjects = extractMaintainerObjects maintainers ++ additionalMaintainerObjects;

  getMaintainerName = maintainer: maintainer.github or maintainer.name or null;

  allMaintainerNames = lib.filter (name: name != null) (map getMaintainerName allMaintainerObjects);

  hmMaintainers = import ../../modules/lib/maintainers.nix;
  hmMaintainerNames = lib.filter (name: name != null) (
    map getMaintainerName (lib.attrValues hmMaintainers)
  );

  maintainerDetails = lib.pipe allMaintainerObjects [
    (lib.filter (obj: (obj.github or obj.name or null) != null))
    (map (
      obj:
      let
        maintainerName = obj.github or obj.name;
      in
      {
        name = maintainerName;
        value = obj // {
          source =
            if categorizedMaintainers.home-manager ? ${maintainerName} then "home-manager" else "nixpkgs";
        };
      }
    ))
    lib.listToAttrs
  ];

  partitionedMaintainers = lib.partition (nameValue: lib.elem nameValue.name hmMaintainerNames) (
    lib.attrsToList maintainerDetails
  );

  categorizedMaintainers = {
    home-manager = lib.listToAttrs partitionedMaintainers.right;
    nixpkgs = lib.listToAttrs partitionedMaintainers.wrong;
  };

  formattedMaintainers = lib.generators.toPretty {
    multiline = true;
    indent = "";
  } maintainerDetails;

in
{
  raw = maintainers;
  names = allMaintainerNames;
  details = maintainerDetails;
  categorized = categorizedMaintainers;
  formatted = formattedMaintainers;

  stats = {
    totalFiles = lib.length (lib.attrNames maintainers);
    totalMaintainers = lib.length allMaintainerNames;
    hmMaintainers = lib.length (lib.attrNames categorizedMaintainers.home-manager);
    nixpkgsMaintainers = lib.length (lib.attrNames categorizedMaintainers.nixpkgs);
  };
}
