{ pkgs, ... }:

let
  package = pkgs.writeScriptBin "windsurf" "" // {
    pname = "windsurf";
    version = "1.9552.25";
  };
in

{
  windsurf-paths =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      argvPath = ".windsurf/argv.json";

      settingsPath =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Application Support/Windsurf/User/settings.json"
        else
          ".config/Windsurf/User/settings.json";
    in
    {
      programs.windsurf = {
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
