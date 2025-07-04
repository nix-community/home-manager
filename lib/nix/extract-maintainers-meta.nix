# Extract maintainers from Home Manager modules using meta.maintainers
# This script evaluates all Home Manager modules and extracts the merged maintainer information
let
  pkgs = import <nixpkgs> { };
  lib = import ../../modules/lib/stdlib-extended.nix pkgs.lib;
  releaseInfo = pkgs.lib.importJSON ../../release.json;

  docsLib = import ../../docs {
    inherit lib pkgs;
    inherit (releaseInfo) release isReleaseBranch;
  };

  moduleMaintainersJson = builtins.fromJSON (builtins.readFile docsLib.jsonModuleMaintainers);
  maintainers = moduleMaintainersJson;

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
          evaluated =
            if lib.isFunction fileContent then
              fileContent {
                inherit (pkgs) stdenv lib;
                documentation-highlighter = { };
                revision = "unknown";
                home-manager-options = {
                  home-manager = { };
                  nixos = { };
                  nix-darwin = { };
                };
                nixos-render-docs = { };
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

  maintainerDetails = lib.pipe allMaintainerObjects [
    (lib.filter (obj: getMaintainerName obj != null))
    (map (obj: {
      name = getMaintainerName obj;
      value = obj;
    }))
    lib.listToAttrs
  ];

  hmMaintainers = import ../../modules/lib/maintainers.nix;
  hmMaintainerNames = lib.attrNames hmMaintainers;

  partitionedMaintainers = lib.partition (nameValue: lib.elem nameValue.name hmMaintainerNames) (
    lib.attrsToList maintainerDetails
  );

  categorizedMaintainers = {
    home-manager = lib.listToAttrs partitionedMaintainers.right;
    nixpkgs = lib.listToAttrs partitionedMaintainers.wrong;
  };

  formatMaintainer =
    name: info: source:
    let
      quotedName =
        if lib.match "[0-9].*" name != null || lib.match "[^a-zA-Z0-9_-].*" name != null then
          ''"${name}"''
        else
          name;

      filteredInfo = lib.filterAttrs (k: v: !lib.hasPrefix "_" k) info;
    in
    "  ${quotedName} = ${
        lib.generators.toPretty {
          multiline = true;
          indent = "    ";
        } filteredInfo
      };";

  formatAllMaintainers =
    let
      hmEntries = lib.mapAttrsToList (
        name: info: formatMaintainer name info "home-manager"
      ) categorizedMaintainers.home-manager;

      nixpkgsEntries = lib.mapAttrsToList (
        name: info: formatMaintainer name info "nixpkgs"
      ) categorizedMaintainers.nixpkgs;
    in
    lib.concatStringsSep "\n" (hmEntries ++ nixpkgsEntries);

in
{
  raw = maintainers;
  names = allMaintainerNames;
  details = maintainerDetails;
  categorized = categorizedMaintainers;
  formatted = formatAllMaintainers;

  stats = {
    totalFiles = lib.length (lib.attrNames maintainers);
    totalMaintainers = lib.length allMaintainerNames;
    hmMaintainers = lib.length (lib.attrNames categorizedMaintainers.home-manager);
    nixpkgsMaintainers = lib.length (lib.attrNames categorizedMaintainers.nixpkgs);
  };
}
