{
  cfg,
  lib,
  pkgs,
  ...
}@inputs:
rec {
  inherit (import ../path-helpers.nix inputs)
    extensionsDirectory
    getAttrKey
    getDefaultProfile
    getOtherProfiles
    hasDefaultProfile
    joinPaths
    ;

  inherit (pkgs.vscode-utils) toExtensionJson;

  profilesExtensionsList = lib.flatten (
    lib.mapAttrsToList (n: profile: profile.extensions) cfg.profiles
  );

  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/editors/vscode/with-extensions.nix#L58
  # Adapted from https://discourse.nixos.org/t/vscode-extensions-setup/1801/2
  extensionsSubDir = "share/vscode/extensions";

  # determines if the VS Code fork supports multiple profiles.
  # this feature is available since VSCode v1.74.0.
  #
  supportsMultiProfiles =
    let
      packageVersion =
        if cfg.package ? vscodeVersion then cfg.package.vscodeVersion else cfg.package.version;

      result = builtins.trace "packageVersion: ${packageVersion}" (
        lib.versionAtLeast packageVersion "1.74.0"
      );
    in
    builtins.trace "supportsMultiProfiles: ${toString result}" result;

  buildExtensionsPaths =
    ext:
    let
      extensionPath = "${ext}/${extensionsSubDir}";

      extensionsPaths =
        if ext ? vscodeExtUniqueId then
          [ ext.vscodeExtUniqueId ]
        else
          builtins.attrNames (builtins.readDir extensionPath);
    in
    lib.map (extPath: {
      "${extensionsDirectory}/${extPath}".source = "${extensionPath}/${extPath}";
    }) extensionsPaths;

  buildMutableExtensionsFiles =
    profileName: profile:
    let
      immutableExtensionsLinkFile = {
        "${extensionsDirectory}/.immutable-extensions.json" = {
          text = toExtensionJson profile.extensions;

          onChange = ''
            echo "Regenerating ${cfg.package.pname} ${extensionsDirectory}/extensions.json"

            run rm $VERBOSE_ARG -f "${extensionsDirectory}"/{extensions.json,.init-default-profile-extensions}
            run ${lib.getExe cfg.package} --list-extensions > /dev/null
          '';
        };
      };

      # mutable extensions (nix and user-managed extensions)
      #
      # - symlinks the extensions directory to the nix-store extensions directory (in the build environment)
      # - creates a symlink to the immutable extensions.json file in the nix-store extensions directory
      # - the extensions directory is mutable and can be modified by the user
      #
      extensionsFiles =
        [ ]
        ++ (lib.concatMap buildExtensionsPaths profilesExtensionsList)
        ++ (lib.optional supportsMultiProfiles immutableExtensionsLinkFile);
    in
    {
      files = builtins.trace "mutable extensionsFiles: ${lib.generators.toPretty { } extensionsFiles}" extensionsFiles;
    };

  buildImmutableExtensionsFiles =
    let
      storeKey = "profile-immutable-extensions";

      mkVSCodeExtensionFile =
        name: text:
        pkgs.writeTextFile {
          inherit text;

          name = "${name}-extensions-json";
          destination = "/${extensionsSubDir}/extensions.json";
        };

      # immutable extensions (only nix-managed extensions)
      #
      # - creates a single build environment containing all extensions
      # - symlinks the entire extensions directory to this build environment
      # - no user extensions allowed - purely nix-managed
      #
      extensionsFiles =
        let
          defaultProfileExtensionsJsonFile = mkVSCodeExtensionFile "default" (
            toExtensionJson getDefaultProfile.extensions
          );

          # nix store derivation for the immutable extensions
          #
          immutableExtensionsJsonDrv = pkgs.buildEnv {
            name = "${cfg.package.pname}-${storeKey}-drv";
            paths =
              [ ]
              # add all the extensions from all profiles
              ++ profilesExtensionsList
              # if multiple profiles are supported and the default profile is set
              # then also add the default profile extensions json file
              ++ lib.optional (supportsMultiProfiles && hasDefaultProfile) defaultProfileExtensionsJsonFile;
          };
        in
        {
          # immutable extensions directory: adapted from https://discourse.nixos.org/t/vscode-extensions-setup/1801/2
          #
          # ~/.cursor/extensions -> /nix/store/cursor-immutable-extensions-drv/share/vscode/extensions/extensions.json
          "${extensionsDirectory}".source = joinPaths [
            (builtins.trace "immutableExtensionsJsonDrv: ${toString immutableExtensionsJsonDrv}" immutableExtensionsJsonDrv)
            (builtins.trace "extensionsSubDir: ${extensionsSubDir}" extensionsSubDir)
          ];
        };
    in
    {
      files = builtins.trace "immutable extensionsFiles: ${lib.generators.toPretty { } extensionsFiles}" extensionsFiles;
    };

  #   Core Decision Tree:
  # - Single profile + mutable flag? → Mutable mode
  # - Multiple profiles? → Immutable mode
  # - Otherwise → Immutable mode
  extensionFiles =
    # mutable extensions are only supported for the default profile if no other profiles are set
    #
    let
      isMutableExtensionsDir = (cfg.mutableExtensionsDir && getOtherProfiles == { });
    in
    if
      builtins.trace "isMutableExtensionsDir: ${toString isMutableExtensionsDir}" isMutableExtensionsDir
    then
      builtins.trace "building mutable extensions files" lib.map (extensions: extensions.files) (
        lib.mapAttrsToList buildMutableExtensionsFiles cfg.profiles
      )
    else
      builtins.trace "building immutable extensions files" [ buildImmutableExtensionsFiles.files ];

}
