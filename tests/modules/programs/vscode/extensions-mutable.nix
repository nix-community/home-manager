{ modulePath, packageName, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  extensionsPath =
    {
      vscode = ".vscode/extensions";
      code-cursor = ".cursor/extensions";
    }
    .${packageName};

  # Create dummy VS Code extensions with identification ids so toExtensionJson works
  # - extA: has vscodeExtUniqueId
  # - extB: has vscodeExtUniqueId
  #
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
in
{
  config =
    { }
    // lib.setAttrByPath modulePath ({
      enable = true;

      # Use a stub package and keep version >= 1.74.0 so that the
      # immutable-extensions.json logic is enabled for this test
      #
      package = config.lib.test.mkStubPackage {
        name = packageName;
        version = "1.75.0";
      };

      # Only default profile → mutable extensions directory behavior
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
        assertDirectoryExists "home-files/${extensionsPath}"
        assertDirectoryExists "home-files/${extensionsPath}/${extAId}"
        assertDirectoryExists "home-files/${extensionsPath}/${extBId}"

        assertFileExists "home-files/${extensionsPath}/${extAId}/.placeholder"
        assertFileExists "home-files/${extensionsPath}/${extBId}/.placeholder"

        # .extensions-immutable.json is created on installation
        #
        assertFileExists "home-files/${extensionsPath}/.extensions-immutable.json"

        # extensions.json is created on activation and should not exist just yet
        #
        assertPathNotExists "home-files/${extensionsPath}/extensions.json"
      '';
    };
}
