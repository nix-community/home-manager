{
  modulePath,
  packageName,
  configDirName,
}:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Create dummy VS Code extensions with different identification modes
  # - extA: has vscodeExtUniqueId → single extension id
  # - extB: has vscodeExtUniqueId → single extension id
  makeExt =
    name: extId: extraAttrs:
    pkgs.runCommand "${packageName}-${name}" ({ } // extraAttrs) ''
      mkdir -p "$out/share/vscode/extensions/${extId}"
      echo ${lib.escapeShellArg name} > "$out/share/vscode/extensions/${extId}/.placeholder"
    '';

  extAId = "publisherA.extA";
  extBId = "publisherB.extB";

  extA = makeExt "extA" extAId {
    version = "1.0.0";
    vscodeExtUniqueId = extAId;
    vscodeExtPublisher = "publisherA";
  };

  extB = makeExt "extB" extBId {
    version = "0.0.1";
    vscodeExtUniqueId = extBId;
    vscodeExtPublisher = "publisherB";
  };

  # Compute the extensions directory root for the target program
  extensionRoot = ".${lib.toLower configDirName}/extensions";
in
{
  config =
    { }
    // lib.setAttrByPath modulePath ({
      enable = true;

      # Use a stub package and keep version >= 1.74.0 so that the
      # extensions.json logic is enabled for this test.
      package = config.lib.test.mkStubPackage {
        name = packageName;
        version = "1.75.0";
      };

      # Force immutable extensions directory behavior
      mutableExtensionsDir = false;

      profiles = {
        default.extensions = [
          extA
          extB
        ];
      };
    })
    // {
      nmt.script = ''
        # extensions are installed as directories with a .placeholder file
        #
        assertDirectoryExists "home-files/${extensionRoot}"
        assertDirectoryExists "home-files/${extensionRoot}/${extAId}"
        assertDirectoryExists "home-files/${extensionRoot}/${extBId}"

        assertFileExists "home-files/${extensionRoot}/${extAId}/.placeholder"
        assertFileExists "home-files/${extensionRoot}/${extBId}/.placeholder"

        # extensions.json is provided by the immutable combined tree
        #
        assertFileExists "home-files/${extensionRoot}/extensions.json"

        # .extensions-immutable.json is not created in immutable mode
        #
        assertPathNotExists "home-files/${extensionRoot}/.extensions-immutable.json"
      '';
    };
}
