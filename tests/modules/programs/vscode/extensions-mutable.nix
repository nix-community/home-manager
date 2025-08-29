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
  # - extA: no vscodeExtUniqueId attribute → discover via directory names
  # - extB: has vscodeExtUniqueId → use that as the single extension id
  makeExt =
    name: extId: extraAttrs:
    pkgs.runCommand "${packageName}-${name}" ({ } // extraAttrs) ''
      mkdir -p "$out/share/vscode/extensions/${extId}"
      echo ${lib.escapeShellArg name} > "$out/share/vscode/extensions/${extId}/.placeholder"
    '';

  extAId = "publisherA.extA";
  extBId = "publisherB.extB";

  extA = makeExt "extA" extAId { };
  extB = makeExt "extB" extBId { vscodeExtUniqueId = extBId; };

  # Compute the extensions directory root for the target program
  extensionRoot = ".${configDirName}/extensions";
in
{
  config =
    { }
    // lib.setAttrByPath modulePath ({
      enable = true;

      # Use a stub package and keep version < 1.74.0 so that the
      # “extensions-immutable.json” logic is disabled for this test.
      package = config.lib.test.mkStubPackage {
        name = packageName;
        version = "1.73.0";
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
        assertFileExists "home-files/${extensionRoot}/${extAId}"
        assertFileExists "home-files/${extensionRoot}/${extBId}"

        # No generated extensions.json or immutable marker in this setup
        #
        assertPathNotExists "home-files/${extensionRoot}/extensions.json"
        assertPathNotExists "home-files/${extensionRoot}/.extensions-immutable.json"
      '';
    };
}
