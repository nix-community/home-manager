# Extract maintainers from Home Manager modules using meta.maintainers
# This script evaluates all Home Manager modules and extracts the merged maintainer information
let
  nixpkgs = import <nixpkgs> { };
  lib = import ../../modules/lib/stdlib-extended.nix nixpkgs.lib;

  # Scrub derivations to avoid instantiating them during evaluation
  scrubDerivations =
    prefixPath: attrs:
    let
      scrubDerivation =
        name: value:
        let
          pkgAttrName = prefixPath + "." + name;
        in
        if lib.isAttrs value then
          scrubDerivations pkgAttrName value
          // lib.optionalAttrs (lib.isDerivation value) {
            outPath = "\${${pkgAttrName}}";
          }
        else
          value;
    in
    lib.mapAttrs scrubDerivation attrs;

  # Make sure the used package is scrubbed to avoid instantiating derivations
  scrubbedPkgsModule = {
    imports = [
      {
        _module.args = {
          pkgs = lib.mkForce (scrubDerivations "pkgs" nixpkgs);
          pkgs_i686 = lib.mkForce { };
        };
      }
    ];
  };

  # Evaluate all Home Manager modules
  hmModules = lib.evalModules {
    modules =
      import ../../modules/modules.nix {
        inherit lib;
        pkgs = nixpkgs;
        check = false;
      }
      ++ [ scrubbedPkgsModule ];
    class = "homeManager";
  };

  inherit (hmModules.config.meta) maintainers;

  extractMaintainerObjects =
    maintainerData:
    lib.pipe maintainerData [
      lib.attrValues
      lib.concatLists
      lib.unique
    ];

  allMaintainerObjects = extractMaintainerObjects maintainers;

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
      # Handle identifiers that start with numbers or contain invalid characters
      quotedName =
        if lib.match "[0-9].*" name != null || lib.match "[^a-zA-Z0-9_-].*" name != null then
          ''"${name}"''
        else
          name;

      # Filter out internal fields
      filteredInfo = lib.filterAttrs (k: v: !lib.hasPrefix "_" k) info;
    in
    "  # ${source}\n  ${quotedName} = ${
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
