modulePath:
{ config, lib, pkgs, ... }:

with lib;

let

  cfg = getAttrFromPath modulePath config;

  firefoxMockOverlay = import ../../setup-firefox-mock-overlay.nix modulePath;

in {
  imports = [ firefoxMockOverlay ];

  config = mkIf config.test.enableBig (setAttrByPath modulePath {
    enable = true;
    profiles = {
      search = {
        id = 0;
        search = {
          force = true;
          default = "Google";
          privateDefault = "DuckDuckGo";
          order = [ "Nix Packages" "NixOS Wiki" ];
          engines = {
            "Nix Packages" = {
              urls = [{
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "type";
                    value = "packages";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }];

              icon =
                "/run/current-system/sw/share/icons/hicolor/scalable/apps/nix-snowflake.svg";

              definedAliases = [ "@np" ];
            };

            "NixOS Wiki" = {
              urls = [{
                template =
                  "https://wiki.nixos.org/index.php?search={searchTerms}";
              }];
              iconUpdateURL = "https://wiki.nixos.org/favicon.png";
              updateInterval = 24 * 60 * 60 * 1000;
              definedAliases = [ "@nw" ];
            };

            "Bing".metaData.hidden = true;
            "Google".metaData.alias = "@g";
          };
        };
      };

      searchWithoutDefault = {
        id = 1;
        search = {
          force = true;
          order = [ "Google" "Nix Packages" ];
          engines = {
            "Nix Packages" = {
              urls = [{
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "type";
                    value = "packages";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }];

              definedAliases = [ "@np" ];
            };
          };
        };
      };
    };
  } // {
    nmt.script = ''
      function assertFirefoxSearchContent() {
        compressedSearch=$(normalizeStorePaths "$1")

        decompressedSearch=$(dirname $compressedSearch)/search.json
        ${pkgs.mozlz4a}/bin/mozlz4a -d "$compressedSearch" >(${pkgs.jq}/bin/jq . > "$decompressedSearch")

        assertFileContent \
          $decompressedSearch \
          "$2"
      }

      assertFirefoxSearchContent \
        home-files/${cfg.configPath}/search/search.json.mozlz4 \
        ${./expected-search.json}

      assertFirefoxSearchContent \
        home-files/${cfg.configPath}/searchWithoutDefault/search.json.mozlz4 \
        ${./expected-search-without-default.json}
    '';
  });
}
