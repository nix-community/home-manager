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

  # Create dummy VS Code extensions
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

      # Disable profile extensions JSON support (version < 1.74.0)
      package = config.lib.test.mkStubPackage {
        # force a pname outside the allowlist to disable JSON support even for Cursor
        name = "vscode";
        # profile extensions JSON not supported by this version
        version = "1.73.0";
      };

      # Multiple profiles → immutable extensions directory behavior
      profiles = {
        default.extensions = [ extA ];
        work.extensions = [ extB ];
      };
    })
    // {
      nmt.script = ''
        # extensions installed via buildEnv should appear as directories
        #
        assertDirectoryExists "home-files/${extensionsPath}"
        assertDirectoryExists "home-files/${extensionsPath}/${extAId}"
        assertDirectoryExists "home-files/${extensionsPath}/${extBId}"

        assertFileExists "home-files/${extensionsPath}/${extAId}/.placeholder"
        assertFileExists "home-files/${extensionsPath}/${extBId}/.placeholder"

        # No extensions JSON files are generated when unsupported
        #
        assertPathNotExists "home-files/${extensionsPath}/.extensions-immutable.json"
        assertPathNotExists "home-files/${extensionsPath}/extensions.json"
      '';
    };
}
