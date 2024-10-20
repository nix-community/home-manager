modulePath:
{ config, lib, ... }:

with lib;

let firefoxMockOverlay = import ../setup-firefox-mock-overlay.nix modulePath;
in {
  imports = [ firefoxMockOverlay ];

  config = mkIf config.test.enableBig (setAttrByPath modulePath {
    enable = true;

    profiles = {
      main = {
        isDefault = true;
        id = 1;
        bookmarks = [{
          toolbar = true;
          bookmarks = [{
            name = "Home Manager";
            url = "https://wiki.nixos.org/wiki/Home_Manager";
          }];
        }];
        containers = {
          "shopping" = {
            icon = "circle";
            color = "yellow";
          };
        };
        search = {
          force = true;
          default = "Google";
          privateDefault = "DuckDuckGo";
          engines = {
            "Bing".metaData.hidden = true;
            "Google".metaData.alias = "@g";
          };
        };
        settings = {
          "general.smoothScroll" = false;
          "browser.newtabpage.pinned" = [{
            title = "NixOS";
            url = "https://nixos.org";
          }];
        };
      };
      "dev-edition-default" = {
        id = 2;
        path = "main";
      };
    };
  });
}
