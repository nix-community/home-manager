{
  lib ? import ../../modules/lib/stdlib-extended.nix (import <nixpkgs> { }).lib,
  file ? throw "provide file argument",
}:
let
  inherit (lib)
    init
    isFunction
    optionalAttrs
    optionals
    ;

  # Minimal module evaluation context
  # NOTE: These are empty/mock values. Modules that deeply access config/options
  # or pkgs attributes may fail evaluation. This is intentional for safety.
  config = { };
  options = { };
  releaseInfo = lib.importJSON ../../release.json;

  # Path utilities with sanitization
  sanitizePath =
    path:
    let
      normalized = lib.removePrefix "/" (lib.removeSuffix "/" path);
    in
    assert !(lib.hasInfix ".." normalized);
    normalized;

  mkAbsolutePath = relPath: ../../. + "/${sanitizePath relPath}";

  isNixFile = lib.hasSuffix ".nix" file;
  filePath = mkAbsolutePath file;
  fileExists = builtins.pathExists filePath;

  findParentModule =
    file:
    let
      pathParts = lib.splitString "/" file;
      fileName = lib.last pathParts;
      fileDir = lib.concatStringsSep "/" (init pathParts);

      sameDirDefault = {
        path = mkAbsolutePath "${fileDir}/default.nix";
        relPath = "${fileDir}/default.nix";
        exists = fileName != "default.nix" && builtins.pathExists (mkAbsolutePath "${fileDir}/default.nix");
      };

      parentParts = init (init pathParts);
      parentDir = lib.concatStringsSep "/" parentParts;
      parentDirDefault = {
        path = mkAbsolutePath "${parentDir}/default.nix";
        relPath = "${parentDir}/default.nix";
        exists = parentParts != [ ] && builtins.pathExists (mkAbsolutePath "${parentDir}/default.nix");
      };

      candidates = lib.filter (c: c.exists) [
        sameDirDefault
        parentDirDefault
      ];
    in
    optionalAttrs (candidates != [ ]) (lib.head candidates);

  # Detect if a function is NOT a standard module (helper function, library function, etc.)
  # Standard modules accept common NixOS/Home Manager parameters.
  isNonModuleFunction =
    fileContent:
    isFunction fileContent
    && (
      let
        functor = builtins.functionArgs fileContent;
        argNames = builtins.attrNames functor;
        # Standard module parameters used across NixOS, Home Manager, and nix-darwin
        standardModuleParams = [
          "config"
          "lib"
          "pkgs"
          "options"
          "modulesPath"
          "specialArgs"
          "osConfig"
          "inputs"
        ];
        hasNonStandardParams = lib.any (name: !(lib.elem name standardModuleParams)) argNames;
      in
      hasNonStandardParams
    );

  # Create a mock pkgs that provides helpful error messages
  # instead of cryptic "null has no attribute" errors
  mockPkgs =
    builtins.mapAttrs
      (
        name: _:
        throw ''
          pkgs.${name} not available during maintainer extraction.
          This is intentional for safety - maintainer extraction runs with minimal context.
          If your module's meta.maintainers depends on pkgs, consider restructuring.
        ''
      )
      {
        stdenv = null;
        lib = null;
        system = null;
        pkgsCross = null;
        buildPackages = null;
      };

  # Module arguments based on file path
  # Priority: specific file overrides > prefix-based args > default args
  mkModuleArgs =
    file:
    let
      # Special case for specific files
      specialCases = {
        "docs/home-manager-manual.nix" = {
          stdenv.mkDerivation = x: x;
          inherit lib;
          documentation-highlighter = { };
          revision = "unknown";
          home-manager-options = {
            home-manager = { };
            nixos = { };
            nix-darwin = { };
          };
          nixos-render-docs = { };
        };
      };

      # Prefix-based argument sets
      prefixArgs =
        if lib.hasPrefix "docs/" file then
          {
            inherit lib;
            pkgs = mockPkgs;
            inherit (releaseInfo) release isReleaseBranch;
          }
        else if lib.hasPrefix "lib/" file then
          { inherit lib; }
        else
          null;

      # Default arguments for standard modules
      defaultArgs = {
        inherit lib config options;
        pkgs = mockPkgs;
      };
    in
    specialCases.${file} or (if prefixArgs != null then prefixArgs else defaultArgs);

  evaluateModule =
    fileContent: file:
    let
      isFunctionContent = isFunction fileContent;
      isHelper = isNonModuleFunction fileContent;

      args = mkModuleArgs file;
    in
    optionalAttrs (!isHelper) (
      builtins.tryEval (if isFunctionContent then fileContent args else fileContent)
    );

  getMaintainers =
    evalResult: optionals (evalResult.success or false) (evalResult.value.meta.maintainers or [ ]);

  getParentMaintainers =
    parentModule:
    optionals (parentModule != { }) (
      let
        parentContent = import parentModule.path;
        parentArgs = {
          inherit lib config options;
          pkgs = mockPkgs;
        };
        parent = if isFunction parentContent then parentContent parentArgs else parentContent;
      in
      parent.meta.maintainers or [ ]
    );

  extractMaintainers =
    let
      fileContent = import filePath;
      evalResult = evaluateModule fileContent file;
      moduleMaintainers = getMaintainers evalResult;

      # Only check parent if no maintainers found directly
      parentModule = optionalAttrs (moduleMaintainers == [ ]) (findParentModule file);
      parentMaintainers = getParentMaintainers parentModule;
    in
    moduleMaintainers ++ parentMaintainers;

  maintainers = optionals (isNixFile && fileExists) extractMaintainers;

in
map (maintainer: maintainer.github) maintainers
