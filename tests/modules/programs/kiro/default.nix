{ pkgs, ... }:

let
  package = pkgs.writeScriptBin "kiro" "" // {
    pname = "kiro";
    version = "0.10.32";
  };
in

{
  kiro-paths =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.programs.kiro;

      argvPath = "${cfg.dataFolderName}/argv.json";

      settingsPath =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Application Support/${cfg.nameShort}/User/settings.json"
        else
          ".config/${cfg.nameShort}/User/settings.json";
    in
    {
      programs.kiro = {
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
