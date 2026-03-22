{ pkgs, ... }:

let
  package = pkgs.writeScriptBin "vscodium" "" // {
    pname = "vscodium";
    version = "1.109.51242";
  };
in

{
  vscodium-paths =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      argvPath = ".vscode-oss/argv.json";

      settingsPath =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Application Support/VSCodium/User/settings.json"
        else
          ".config/VSCodium/User/settings.json";
    in
    {
      programs.vscodium = {
        enable = true;
        inherit package;
        argvSettings.enable-crash-reporter = false;
        profiles.default = {
          enableUpdateCheck = false;
          enableExtensionUpdateCheck = false;
        };
      };

      nmt.script = ''
        assertFileExists "home-files/${argvPath}"
        assertFileExists "home-files/${settingsPath}"
      '';
    };
}
