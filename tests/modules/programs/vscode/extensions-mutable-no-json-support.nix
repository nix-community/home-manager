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

  # Create dummy VS Code extensions. extA lacks vscodeExtUniqueId to exercise
  # directory enumeration when JSON support is disabled.
  # - extA: no vscodeExtUniqueId (enumeration path)
  # - extB: has vscodeExtUniqueId (id path)
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

      # Disable profile extensions JSON support by using version < 1.74.0 and
      # a package name outside the allowlist (e.g., not "code-cursor").
      # This ensures no extensions.json/.extensions-immutable.json are generated.
      package = config.lib.test.mkStubPackage {
        # force a pname outside the allowlist to disable JSON support even for Cursor
        name = "vscode";

        # profile extensions JSON not supported by this version
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
        # extensions are installed as directories with a .placeholder file
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
