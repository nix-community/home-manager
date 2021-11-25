{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.firefox = {
      enable = true;
      profiles.basic.isDefault = true;

      profiles.test = {
        id = 1;
        settings = { "general.smoothScroll" = false; };
      };

      profiles.bookmarks = {
        id = 2;
        settings = { "general.smoothScroll" = false; };
        bookmarks = {
          wikipedia = {
            keyword = "wiki";
            url =
              "https://en.wikipedia.org/wiki/Special:Search?search=%s&go=Go";
          };
          "kernel.org" = { url = "https://www.kernel.org"; };
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
    '';
  };
}
