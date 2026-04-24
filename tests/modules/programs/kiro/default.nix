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
      pkgs,
      ...
    }:
    let
      argvPath = ".kiro/argv.json";

      settingsPath =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Application Support/Kiro/User/settings.json"
        else
          ".config/Kiro/User/settings.json";
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
