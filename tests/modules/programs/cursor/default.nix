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
      argvPath = ".cursor/argv.json";

      settingsPath =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Application Support/Cursor/User/settings.json"
        else
          ".config/Cursor/User/settings.json";
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
