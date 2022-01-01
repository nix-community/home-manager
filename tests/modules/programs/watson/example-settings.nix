{ config, lib, pkgs, ... }:

with lib;

{
  programs.watson = {
    enable = true;
    package = config.lib.test.mkStubPackage { };

    settings = {
      backend = {
        url = "https://api.crick.fr";
        token = "yourapitoken";
      };

      options = {
        stop_on_start = true;
        stop_on_restart = false;
        date_format = "%Y.%m.%d";
        time_format = "%H:%M:%S%z";
        week_start = "monday";
        log_current = false;
        pager = true;
        report_current = false;
        reverse_log = true;
      };
    };
  };

  nmt.script = let
    configDir = if pkgs.stdenv.hostPlatform.isDarwin then
      "home-files/Library/Application Support"
    else
      "home-files/.config";
  in ''
    assertFileContent \
      "${configDir}/watson/config" \
      ${./example-settings-expected.ini}
  '';
}
