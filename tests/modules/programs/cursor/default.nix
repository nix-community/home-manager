{ pkgs, ... }:

let
  package = pkgs.writeScriptBin "cursor" "" // {
    pname = "cursor";
    version = "2.5.26";
  };
in

{
  cursor-paths =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.programs.cursor;

      argvPath = "${cfg.dataFolderName}/argv.json";

      settingsPath =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Application Support/${cfg.nameShort}/User/settings.json"
        else
          ".config/${cfg.nameShort}/User/settings.json";
    in
    {
      programs.cursor = {
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
