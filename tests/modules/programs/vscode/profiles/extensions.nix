{
  forkInputs,
  lib,
  pkgs,
  ...
}@inputs:
let
  inherit (import ../test-helpers.nix inputs) mkVSCodeExtension;

  extensionAId = "publisherA.extA";
  extensionBId = "publisherB.extB";
  extensionCId = "publisherC.extC";

  extensionA = mkVSCodeExtension "extensionA" extensionAId {
    version = "0.0.1";
    vscodeExtUniqueId = extensionAId;
    vscodeExtPublisher = "publisherA";
  };

  extensionB = mkVSCodeExtension "extensionB" extensionBId {
    version = "0.0.2";
    vscodeExtUniqueId = extensionBId;
    vscodeExtPublisher = "publisherB";
  };

  extensionC = mkVSCodeExtension "extensionC" extensionCId {
    version = "0.0.3";
    vscodeExtUniqueId = extensionCId;
    vscodeExtPublisher = "publisherC";
  };

  # modules/programs/vscode/vscodeFork.nix#L51
  #
  # mutableExtensionsDir is only supported for the default profile if no other profiles
  # are set, otherwise extensions are immutable by default.
  #
  # when testing multiple profiles, we set mutableExtensionsDir to false to mimic the
  # default behavior and add a work profile to test if we can also install extensions
  # in other profiles.
  #
  #   - vscodeVersion < 1.74.0, mutableExtensionsDir = <any> -> profiles: [default]
  #   - vscodeVersion >= 1.74.0, mutableExtensionsDir = true -> profiles: [default]
  #   - vscodeVersion >= 1.74.0, mutableExtensionsDir = false -> profiles: [default, work]
  #
  supportsMultiProfiles =
    let
      vscodeVersion =
        if forkInputs.package ? vscodeVersion then
          forkInputs.package.vscodeVersion
        else
          forkInputs.package.version;
    in
    lib.versionAtLeast vscodeVersion "1.74.0";

  isMutableExtensionsDir =
    if (forkInputs ? mutableExtensionsDir) then forkInputs.mutableExtensionsDir else true;

  # dynamically add the work profile if multiple profiles are supported and the extensions directory is mutable
  #
  hasMultipleProfiles = supportsMultiProfiles && !isMutableExtensionsDir;

  forkConfig = forkInputs // {
    profiles = {
      default = {
        extensions = [
          extensionA
          extensionC
        ];
      };
    }
    // lib.optionalAttrs hasMultipleProfiles {
      work = {
        extensions = [ extensionB ];
      };
    };
  };

  extensionsPath =
    if forkInputs ? dataFolderName && forkInputs.dataFolderName != null then
      "${forkInputs.dataFolderName}/extensions"
    else
      ".${lib.toLower forkInputs.moduleName}/extensions";
in
{
  config = lib.setAttrByPath [ "programs" forkInputs.moduleName ] forkConfig // {
    nmt.script = ''
      assertDirectoryExists "home-files/${extensionsPath}"

      if [[ -n "${toString isMutableExtensionsDir}" ]]; then
        assertFileExists "home-files/${extensionsPath}/.immutable-extensions.json"
      else
        # the extensions directory is immutable and linked to the nix store derivation,
        # e.g. /nix/store/<hash>/package-name-profile-immutable-extensions-drv/share/vscode/extensions
        #
        assertLinkExists "home-files/${extensionsPath}"
      fi;

      # default profile: extensionA and extensionC are always installed
      #
      assertDirectoryExists "home-files/${extensionsPath}/${extensionAId}"
      assertDirectoryExists "home-files/${extensionsPath}/${extensionCId}"

      assertLinkExists "home-files/${extensionsPath}/${extensionAId}"
      assertLinkExists "home-files/${extensionsPath}/${extensionCId}"

      assertLinkPointsTo "home-files/${extensionsPath}/${extensionAId}" "${extensionA}/share/vscode/extensions/${extensionAId}"
      assertLinkPointsTo "home-files/${extensionsPath}/${extensionCId}" "${extensionC}/share/vscode/extensions/${extensionCId}"

      assertFileExists "home-files/${extensionsPath}/${extensionAId}/.placeholder"
      assertFileExists "home-files/${extensionsPath}/${extensionCId}/.placeholder"

      # work profile: extensionB is only installed in the work profile
      #
      if [[ -n "${toString hasMultipleProfiles}" ]]; then
        assertDirectoryExists "home-files/${extensionsPath}/${extensionBId}"
        assertLinkExists "home-files/${extensionsPath}/${extensionBId}"
        assertLinkPointsTo "home-files/${extensionsPath}/${extensionBId}" "${extensionB}/share/vscode/extensions/${extensionBId}"
        assertFileExists "home-files/${extensionsPath}/${extensionBId}/.placeholder"
      else
        assertPathNotExists "home-files/${extensionsPath}/${extensionBId}/.placeholder"
      fi;
    '';
  };
}
