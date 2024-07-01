{ config, lib, pkgs, ... }:

{
  imports = [ ./setup-firefox-mock-overlay.nix ];

  config = lib.mkIf config.test.enableBig {
    home.stateVersion = "23.11";
    programs.firefox = {
      enable = true;
      package = pkgs.librewolf;

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
        search = {
          force = true;
          default = "DuckDuckGo";
          privateDefault = "DuckDuckGo";
        };
      };
    };

    nmt.script = ''
      assertFileRegex \
        home-path/bin/librewolf \
        MOZ_APP_LAUNCHER

      assertDirectoryExists home-files/.librewolf/basic

      assertFileContent \
        home-files/.librewolf/test/user.js \
        ${./profile-settings-expected-user.js}

      function assertFirefoxSearchContent() {
        compressedSearch=$(normalizeStorePaths "$1")

        decompressedSearch=$(dirname $compressedSearch)/search.json
        ${pkgs.mozlz4a}/bin/mozlz4a -d "$compressedSearch" >(${pkgs.jq}/bin/jq . > "$decompressedSearch")

        assertFileContent \
          $decompressedSearch \
          "$2"
      }

      assertFirefoxSearchContent \
        home-files/.librewolf/test/search.json.mozlz4 \
        ${./profile-settings-expected-search-with-librewolf.json}
    '';
  };
}
