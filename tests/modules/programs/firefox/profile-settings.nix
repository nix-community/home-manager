{ config, lib, pkgs, ... }:

with lib;

lib.mkIf config.test.enableBig {
  programs.firefox = {
    enable = true;
    profiles.basic.isDefault = true;

    profiles.test = {
      id = 1;
      settings = {
        "general.smoothScroll" = false;
        "browser.newtabpage.pinned" = [{
          title = "NixOS";
          url = "https://nixos.org";
        }];
      };
    };

    profiles.bookmarks = {
      id = 2;
      settings = { "general.smoothScroll" = false; };
      bookmarks = [
        {
          toolbar = true;
          bookmarks = [{
            name = "Home Manager";
            url = "https://nixos.wiki/wiki/Home_Manager";
          }];
        }
        {
          name = "wikipedia";
          keyword = "wiki";
          url = "https://en.wikipedia.org/wiki/Special:Search?search=%s&go=Go";
        }
        {
          name = "kernel.org";
          url = "https://www.kernel.org";
        }
        {
          name = "Nix sites";
          bookmarks = [
            {
              name = "homepage";
              url = "https://nixos.org/";
            }
            {
              name = "wiki";
              url = "https://nixos.wiki/";
            }
            {
              name = "Nix sites";
              bookmarks = [
                {
                  name = "homepage";
                  url = "https://nixos.org/";
                }
                {
                  name = "wiki";
                  url = "https://nixos.wiki/";
                }
              ];
            }
          ];
        }
      ];
    };

    profiles.search = {
      id = 3;
      search = {
        force = true;
        default = "DuckDuckGo";
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
              template = "https://nixos.wiki/index.php?search={searchTerms}";
            }];
            iconUpdateURL = "https://nixos.wiki/favicon.png";
            updateInterval = 24 * 60 * 60 * 1000;
            definedAliases = [ "@nw" ];
          };

          "Bing".metaData.hidden = true;
          "Google".metaData.alias = "@g";
        };
      };
    };

    profiles.searchWithoutDefault = {
      id = 4;
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

  nixpkgs.overlays = [
    (self: super: {
      firefox-unwrapped = pkgs.runCommand "firefox-0" {
        meta.description = "I pretend to be Firefox";
        preferLocalBuild = true;
        passthru.gtk3 = null;
      } ''
        mkdir -p "$out"/{bin,lib}
        touch "$out/bin/firefox"
        chmod 755 "$out/bin/firefox"
      '';
    })
  ];

  nmt.script = ''
    assertFileRegex \
      home-path/bin/firefox \
      MOZ_APP_LAUNCHER

    assertDirectoryExists home-files/.mozilla/firefox/basic

    assertFileContent \
      home-files/.mozilla/firefox/test/user.js \
      ${./profile-settings-expected-user.js}

    bookmarksUserJs=$(normalizeStorePaths \
      home-files/.mozilla/firefox/bookmarks/user.js)

    assertFileContent \
      $bookmarksUserJs \
      ${./profile-settings-expected-bookmarks-user.js}

    bookmarksFile="$(sed -n \
      '/browser.bookmarks.file/ {s|^.*\(/nix/store[^"]*\).*|\1|;p}' \
      $TESTED/home-files/.mozilla/firefox/bookmarks/user.js)"

    assertFileContent \
      $bookmarksFile \
      ${./profile-settings-expected-bookmarks.html}

    function assertFirefoxSearchContent() {
      compressedSearch=$(normalizeStorePaths "$1")

      decompressedSearch=$(dirname $compressedSearch)/search.json
      ${pkgs.mozlz4a}/bin/mozlz4a -d "$compressedSearch" >(${pkgs.jq}/bin/jq . > "$decompressedSearch")

      assertFileContent \
        $decompressedSearch \
        "$2"
    }

    assertFirefoxSearchContent \
      home-files/.mozilla/firefox/search/search.json.mozlz4 \
      ${./profile-settings-expected-search.json}

    assertFirefoxSearchContent \
      home-files/.mozilla/firefox/searchWithoutDefault/search.json.mozlz4 \
      ${./profile-settings-expected-search-without-default.json}
  '';
}
