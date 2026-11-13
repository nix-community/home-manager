{ pkgs, ... }:

let
  package = pkgs.writeScriptBin "positron" "" // {
    pname = "positron-bin";
    version = "2026.07.1-5";
  };
in

{
  positron-paths =
    { pkgs, ... }:
    let
      argvPath = ".positron/argv.json";

      settingsPath =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Application Support/Positron/User/settings.json"
        else
          ".config/Positron/User/settings.json";
    in
    {
      programs.positron = {
        inherit package;

        enable = true;
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
