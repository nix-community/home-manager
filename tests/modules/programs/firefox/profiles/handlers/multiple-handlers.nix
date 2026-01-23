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
      profiles.multiple-handlers = {
        id = 0;
        handlers = {
          mimeTypes = {
            "image/jpeg" = {
              action = 2;
              ask = true;
              handlers = [
                {
                  name = "Viewer";
                  path = "${pkgs.hello}/bin/hello";
                }
                {
                  name = "Editor";
                  path = "${pkgs.hello}/bin/hello";
                }
              ];
              extensions = [
                "jpg"
                "jpeg"
              ];
            };
          };
          schemes = {
            https = {
              action = 2;
              ask = false;
              handlers = [
                { }
                {
                  uriTemplate = "https://app1.example.com/?url=%s";
                }
                {
                  name = "App 2";
                  uriTemplate = "https://app2.example.com/?url=%s";
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
          home-files/${cfg.configPath}/multiple-handlers/handlers.json \
          ${./expected-multiple-handlers.json}
      '';
    }
  );
}
