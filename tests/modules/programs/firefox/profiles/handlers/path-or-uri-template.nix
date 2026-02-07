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
in
{
  imports = [ firefoxMockOverlay ];

  config = lib.mkIf config.test.enableBig (
    lib.setAttrByPath modulePath {
      enable = true;

      profiles.test = {
        id = 0;
        handlers = {
          mimeTypes = {
            "application/pdf" = {
              action = 2;
              handlers = [
                {
                  name = "PDF Reader";
                  path = "${pkgs.hello}/bin/hello";
                }
              ];
            };
          };
          schemes = {
            "mailto" = {
              action = 2;
              ask = true;
              handlers = [
                {
                  name = "Mail Client";
                  uriTemplate = "https://mail.example.com/?to=%s";
                }
              ];
            };
          };
        };
      };
    }
    // {
      nmt.script = ''
        assertFileContent \
          home-files/${cfg.configPath}/test/handlers.json \
          ${./expected-path-or-uri.json}
      '';
    }
  );
}
