{
  package,
  packageName ? package.pname,
  ...
}@forkInputs:
{
  config,
  lib,
  pkgs,
  ...
}@inputs:
let
  inherit (import ../test-helpers.nix (forkInputs // inputs))
    settingsJsonObject
    settingsJsonPath
    userDirectory
    ;

  forkConfig = forkInputs // {
    profiles = {
      default = {
        settings = settingsJsonPath;

        enableUpdateCheck = false;
        enableExtensionUpdateCheck = false;
      };
      work = {
        settings = settingsJsonObject;

        enableUpdateCheck = false;
        enableExtensionUpdateCheck = false;
      };
    };
  };
in
{
  config = lib.setAttrByPath [ "programs" package.pname ] forkConfig // {
    nmt.script = ''
      assertFileExists "home-files/${userDirectory}/settings.json"
      assertFileContent "home-files/${userDirectory}/settings.json" "${settingsJsonPath}"

      assertFileExists "home-files/${userDirectory}/profiles/work/settings.json"
      assertFileContent "home-files/${userDirectory}/profiles/work/settings.json" "${settingsJsonPath}"
    '';
  };
}
