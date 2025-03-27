modulePath:
{ config, lib, pkgs, ... }:

let firefoxMockOverlay = import ../../setup-firefox-mock-overlay.nix modulePath;
in {
  imports = [ firefoxMockOverlay ];

  config = lib.mkIf config.test.enableBig (lib.setAttrByPath modulePath {
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
    nmt.script = let
      isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
      profilePath = if isDarwin then
        "Library/Application Support/Firefox/Profiles"
      else
        ".mozilla/firefox";
    in ''
      assertFileContent \
        "home-files/${profilePath}/extensions/browser-extension-data/uBlock0@raymondhill.net/storage.js" \
        ${./expected-storage.js}
    '';
  });
}
