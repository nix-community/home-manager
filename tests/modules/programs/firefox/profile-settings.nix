{ config, lib, pkgs, ... }:

with lib;

lib.mkIf config.test.enableBig {
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
          ];
        }
      ];
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
}
