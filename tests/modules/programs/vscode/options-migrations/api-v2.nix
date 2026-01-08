{
  forkInputs,
  lib,
  pkgs,
  ...
}@inputs:
let
  inherit (import ../test-helpers.nix inputs) mkVSCodeExtension;

  extensionId = "publisherA.extA";

  vsCodeExtension = mkVSCodeExtension "vscode" extensionId {
    version = "0.0.1";
    vscodeExtUniqueId = extensionId;
    vscodeExtPublisher = "publisherA";
  };

  # api.v2: migrate immutableExtensionsDir to mutableExtensionsDir
  #
  forkConfig = forkInputs // {
    immutableExtensionsDir = true; # mutableExtensionsDir = !immutableExtensionsDir

    extensions = [ vsCodeExtension ];
  };

  extensionsPath =
    if forkInputs ? dataFolderName && forkInputs.dataFolderName != null then
      "${forkInputs.dataFolderName}/extensions"
    else
      ".${lib.toLower forkInputs.moduleName}/extensions";
in
{
  config = lib.setAttrByPath [ "programs" forkInputs.moduleName ] forkConfig // {
    test.asserts.warnings.expected = [
      "The option `programs.${forkInputs.moduleName}.extensions' defined in `<unknown-file>' has been renamed to `programs.${forkInputs.moduleName}.profiles.default.extensions'."
      "The option `programs.${forkInputs.moduleName}.immutableExtensionsDir' defined in `<unknown-file>' has been changed to `programs.${forkInputs.moduleName}.mutableExtensionsDir' that has a different type. Please read `programs.${forkInputs.moduleName}.mutableExtensionsDir' documentation and update your configuration accordingly."
    ];

    nmt.script = ''
      assertDirectoryExists "home-files/${extensionsPath}"
      assertLinkExists "home-files/${extensionsPath}"
    '';
  };
}
