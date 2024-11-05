modulePath:
{ config, lib, pkgs, ... }:

with lib;

let

  cfg = getAttrFromPath modulePath config;

  firefoxMockOverlay = import ../../setup-firefox-mock-overlay.nix modulePath;

  withName = path:
    pkgs.substituteAll {
      src = path;
      name = cfg.wrappedPackageName;
    };

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
    nmt.script = let

      noHashQuery = ''
        'def walk(f):
             . as $in
             | if type == "object" then
                 reduce keys[] as $key
                 ( {}; . + { ($key): ($in[$key] | walk(f)) } | f )
               elif type == "array" then
                 map( walk(f) )
               else
                 f
               end;
             walk(if type == "object" then
                     if has("hash") then .hash = null else . end |
                     if has("privateHash") then .privateHash = null else . end
                  else
                     .
                  end)' '';

    in ''
      function assertFirefoxSearchContent() {
        compressedSearch=$(normalizeStorePaths "$1")

        decompressedSearch=$(dirname $compressedSearch)/search.json
        ${pkgs.mozlz4a}/bin/mozlz4a -d "$compressedSearch" >(${pkgs.jq}/bin/jq ${noHashQuery} > "$decompressedSearch")

        assertFileContent \
          $decompressedSearch \
          "$2"
      }

      assertFirefoxSearchContent \
        home-files/${cfg.configPath}/search/search.json.mozlz4 \
        ${withName ./expected-search.json}

      assertFirefoxSearchContent \
        home-files/${cfg.configPath}/searchWithoutDefault/search.json.mozlz4 \
        ${withName ./expected-search-without-default.json}
    '';
  });
}
