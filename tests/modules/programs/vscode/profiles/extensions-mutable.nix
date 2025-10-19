{ package, ... }@forkInputs:
{
  cfg,
  lib,
  pkgs,
  ...
}@inputs:
let
  makeExt =
    extName: extId: extraAttrs:
    let
      extensionName = "${package.pname}-${extName}-extension";
      extensionDir = "$out/share/${package.pname}/extensions/${extId}";
    in
    pkgs.runCommand extensionName ({ } // extraAttrs) ''
      mkdir -p "${extensionDir}"
      echo "${lib.escapeShellArg extName}-${extId}" > "${extensionDir}/.placeholder"
    '';

  extensionAId = "publisherA.extA";
  extensionBId = "publisherB.extB";

  extensionA = makeExt "extensionA" extensionAId {
    version = "1.0.0";
    vscodeExtUniqueId = extensionAId;
    vscodeExtPublisher = "publisherA";
  };

  extensionB = makeExt "extensionB" extensionBId {
    version = "0.0.1";
    vscodeExtUniqueId = extensionBId;
    vscodeExtPublisher = "publisherB";
  };

  forkConfig = forkInputs // {
    mutableExtensionsDir = true; # force mutable extensions directory

    profiles = {
      default.extensions = [
        extensionA
        extensionB
      ];
    };
  };

  extensionsPath = ".${lib.toLower package.pname}/extensions";
in
{
  config = lib.setAttrByPath [ "programs" package.pname ] forkConfig // {
    nmt.script = ''
      # extensions are installed as directories with a .placeholder file
      #
      assertDirectoryExists "home-files/${extensionsPath}"
      assertDirectoryExists "home-files/${extensionsPath}/${extensionAId}"
      assertDirectoryExists "home-files/${extensionsPath}/${extensionBId}"

      assertFileExists "home-files/${extensionsPath}/${extensionAId}/.placeholder"
      assertFileExists "home-files/${extensionsPath}/${extensionBId}/.placeholder"

      # immutable-extensions.json is created on installation
      #
      assertFileExists "home-files/${extensionsPath}/.immutable-extensions.json"

      # extensions.json is created on activation and should not exist just yet
      #
      assertPathNotExists "home-files/${extensionsPath}/extensions.json"
    '';
  };
}
