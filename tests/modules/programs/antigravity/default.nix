{ pkgs, ... }:

let
  package = pkgs.writeScriptBin "antigravity" "" // {
    pname = "antigravity";
    version = "1.11.14";
  };
in

{
  antigravity-paths =
    {
      pkgs,
      ...
    }:
    let
      argvPath = ".antigravity/argv.json";

      settingsPath =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Application Support/Antigravity/User/settings.json"
        else
          ".config/Antigravity/User/settings.json";
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
