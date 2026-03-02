{ pkgs, lib, ... }:

let
  package = pkgs.writeScriptBin "antigravity" "" // {
    pname = "antigravity";
    version = "1.11.14";
  };
in

{
  antigravity-paths =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.programs.antigravity;

      argvPath = "${cfg.dataFolderName}/argv.json";

      settingsPath =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Application Support/${cfg.nameShort}/User/settings.json"
        else
          ".config/${cfg.nameShort}/User/settings.json";
    in
    {
      programs.antigravity = {
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
