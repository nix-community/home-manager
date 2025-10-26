{
  cfg,
  lib,
  pkgs,
  ...
}@inputs:
rec {
  inherit (pkgs.vscode-utils) toExtensionJson;

  inherit (import ../path-helpers.nix inputs)
    extensionsDirectory
    getDefaultProfile
    getOtherProfiles
    hasDefaultProfile
    hasOtherProfiles
    supportsMultiProfiles
    joinPaths
    profileDirectory
    ;

  # vscode extensions directory: https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/editors/vscode/with-extensions.nix#L60
  # also adapted from: https://discourse.nixos.org/t/vscode-extensions-setup/1801/2
  #
  vscodeShareExtensionsDirectory = "share/vscode/extensions";

  # builds the extensions paths for a given extension
  #
  # - symlinks from the immutable extension directory to the nix store extension directory
  # - extensions can be updated because it downloads a new version into the mutable extensions directory
  #
  buildExtensionsPaths =
    ext:
    let
      extensionPath = "${ext}/${vscodeShareExtensionsDirectory}";

      extensionsPaths =
        if ext ? vscodeExtUniqueId then
          [ ext.vscodeExtUniqueId ]
        else
          builtins.attrNames (builtins.readDir extensionPath);

      buildPath =
        extPath:
        let
          pathKey = joinPaths [
            extensionsDirectory
            extPath
          ];
          pathValue = joinPaths [
            extensionPath
            extPath
          ];
        in
        {
          "${pathKey}".source = pathValue;
        };
    in
    lib.map buildPath extensionsPaths;

  allExtensions = lib.flatten (lib.mapAttrsToList (n: profile: profile.extensions) cfg.profiles);

  createExtensionSymlinks = extensions: lib.concatMap buildExtensionsPaths extensions;

  createExtensionJsonFile =
    profileName: extensions:
    pkgs.writeTextFile {
      name = "${profileName}-extensions-json";
      text = toExtensionJson extensions;
      destination = "/${vscodeShareExtensionsDirectory}/extensions.json";
    };

  createImmutableProfileExtensionsJson =
    profiles:
    lib.mapAttrs' (
      profileName: profile:
      let
        extensionJsonFile = createExtensionJsonFile profileName profile.extensions;
      in
      lib.nameValuePair "${profileDirectory profileName}/extensions.json" {
        source = (
          joinPaths [
            extensionJsonFile
            vscodeShareExtensionsDirectory
            "extensions.json"
          ]
        );
      }
    ) profiles;

  createMutableProfileExtensionsJson =
    profiles:
    lib.mapAttrs' (
      profileName: profile:
      lib.nameValuePair "${extensionsDirectory}/.immutable-extensions.json" {
        text = toExtensionJson profile.extensions;

        onChange = ''
          echo "Regenerating ${cfg.package.pname} ${extensionsDirectory}/extensions.json"

          run rm $VERBOSE_ARG -f "${extensionsDirectory}"/{extensions.json,.init-default-profile-extensions}
          run $VERBOSE_ARG ${lib.getExe cfg.package} --list-extensions > /dev/null
        '';
      }
    ) profiles;

  createCombinedBuildEnvironment =
    extensionsPaths:
    let
      combinedBuildEnv = pkgs.buildEnv {
        name = "${cfg.package.pname}-profile-immutable-combined-extensions-drv";
        paths = extensionsPaths;
      };
    in
    {
      "${extensionsDirectory}".source = joinPaths [
        combinedBuildEnv
        vscodeShareExtensionsDirectory
      ];
    };

  mutableExtensionsFiles = [
    (createExtensionSymlinks allExtensions) # symlinks from the immutable extension directory to the nix store extension directory
    (createMutableProfileExtensionsJson { default = getDefaultProfile; }) # mutable profile extensions.json file
  ];

  immutableExtensionsFiles =
    let
      combinedExtensionsPaths = lib.flatten ([
        allExtensions
        (lib.optional (supportsMultiProfiles && hasDefaultProfile) (
          createExtensionJsonFile "default" getDefaultProfile.extensions
        ))
      ]);
    in
    [
      (createExtensionSymlinks allExtensions) # symlinks from the immutable ext-dir to the nix store ext-dir
      (createImmutableProfileExtensionsJson getOtherProfiles) # immutable profiles' extensions.json files
      (createCombinedBuildEnvironment combinedExtensionsPaths) # combined build drv for all extensions (and maybe default profile too)
    ];

  extensionFiles =
    if (cfg.mutableExtensionsDir && !hasOtherProfiles) then
      mutableExtensionsFiles
    else
      immutableExtensionsFiles;
}
