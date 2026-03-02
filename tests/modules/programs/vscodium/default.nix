{ pkgs, lib, ... }:

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
      cfg = config.programs.vscodium;

      argvPath = "${cfg.dataFolderName}/argv.json";

      settingsPath =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Application Support/${cfg.nameShort}/User/settings.json"
        else
          ".config/${cfg.nameShort}/User/settings.json";
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
