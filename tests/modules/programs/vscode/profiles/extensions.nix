{
  forkInputs,
  lib,
  pkgs,
  ...
}@inputs:
let
  inherit (import ../test-helpers.nix inputs) isMutableProfile;

  makeExt =
    extName: extId: extraAttrs:
    let
      extensionName = "${forkConfig.package.pname}-${extName}-extension";
      extensionDir = "$out/share/${forkConfig.package.pname}/extensions/${extId}";
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

  isMutable = true;

  forkConfig = forkInputs // {
    mutableExtensionsDir = isMutable;

    profiles = {
      default = {
        extensions = [
          extensionA
          extensionB
        ];
      };
    };
  };

  extensionsPath = ".${lib.toLower forkConfig.package.pname}/extensions";
in
{
  config = lib.setAttrByPath [ "programs" forkConfig.package.pname ] forkConfig // {
    nmt.script = ''
      # mutable profiles create immutable nix store files and mutable copies on activation
      # immutable profiles create immutable nix store files linked to the files themselves
      #
      if [[ -n "${toString isMutableProfile}" ]]; then
        # creates the immutable extensions.json file
        #
        assertFileExists "home-files/${extensionsPath}/.immutable-extensions.json"

        # mutable copies are created only during activation
        #
        assertPathNotExists "home-files/${extensionsPath}/extensions.json"
      else
        # the immutable links are not created because the files are immutable by default
        #
        assertPathNotExists "home-files/${extensionsPath}/.extensions-immutable.json"
      fi;

      assertDirectoryExists "home-files/${extensionsPath}"
      assertDirectoryExists "home-files/${extensionsPath}/${extensionAId}"
      assertDirectoryExists "home-files/${extensionsPath}/${extensionBId}"

      assertFileExists "home-files/${extensionsPath}/${extensionAId}/.placeholder"
      assertFileExists "home-files/${extensionsPath}/${extensionBId}/.placeholder"
    '';
  };
}
