modulePath:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = lib.getAttrFromPath modulePath config;
  firefoxMockOverlay = import ../../setup-firefox-mock-overlay.nix modulePath;
  testCfg = {
    action = 2;
    ask = false;
    handlers = [
      { } # Empty handler object - no default
      {
        name = "Default App";
        path = "${pkgs.hello}/bin/hello";
      }
    ];
  };
in
{
  imports = [ firefoxMockOverlay ];

  config = lib.mkIf config.test.enableBig (
    lib.setAttrByPath modulePath {
      enable = true;
      profiles.no-default-handler = {
        id = 0;
        handlers = {
          mimeTypes."application/pdf" = testCfg;
          schemes.https = testCfg;
        };
      };
    }
    // {
      nmt.script = ''
        assertFileContent \
          home-files/${cfg.configPath}/no-default-handler/handlers.json \
          ${./expected-no-default-handler.json}
      '';
    }
  );
}
