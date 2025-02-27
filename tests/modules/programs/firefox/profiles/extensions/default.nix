modulePath:
{ config, lib, ... }:
with lib;
let
  cfg = getAttrFromPath modulePath config;

  firefoxMockOverlay = import ../../setup-firefox-mock-overlay.nix modulePath;
in {
  imports = [ firefoxMockOverlay ];

  config = mkIf config.test.enableBig (setAttrByPath modulePath {
    enable = true;
    profiles.extensions = {
      extensions = {
        force = true;
        settings = {
          "uBlock0@raymondhill.net".settings = {
            selectedFilterLists = [
              "ublock-filters"
              "ublock-badware"
              "ublock-privacy"
              "ublock-unbreak"
              "ublock-quick-fixes"
            ];
          };
        };
      };
    };
  } // {
    nmt.script = ''
      assertFileContent \
        home-files/${cfg.configPath}/extensions/browser-extension-data/uBlock0@raymondhill.net/storage.js \
        ${./expected-storage.js}
    '';
  });
}
