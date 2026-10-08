modulePath:
{ config, lib, ... }:

let

  cfg = lib.getAttrFromPath modulePath config;

  firefoxMockOverlay = import ../../setup-firefox-mock-overlay.nix modulePath;

in
{
  imports = [ firefoxMockOverlay ];

  config = lib.mkIf config.test.enableBig (
    lib.setAttrByPath modulePath {
      enable = true;
      profiles.bookmarks = {
        settings = {
          "general.smoothScroll" = false;
        };
        bookmarks = {
          home-manager = {
            toolbar = true;
            bookmarks = [
              {
                name = "Home Manager";
                url = "https://wiki.nixos.org/wiki/Home_Manager";
              }
            ];
          };
          wikipedia = {
            name = "wikipedia";
            tags = [ "wiki" ];
            keyword = "wiki";
            url = "https://en.wikipedia.org/wiki/Special:Search?search=%s&go=Go";
          };
          kernel-org = {
            name = "kernel.org";
            url = "https://www.kernel.org";
          };
          nix-sites = {
            name = "Nix sites";
            bookmarks = [
              {
                name = "homepage";
                url = "https://nixos.org/";
              }
              {
                name = "wiki";
                tags = [
                  "wiki"
                  "nix"
                ];
                url = "https://wiki.nixos.org/";
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
                    url = "https://wiki.nixos.org/";
                  }
                ];
              }
            ];
          };
        };
      };
    }
    // {
      test.asserts.warnings.expected = [
        ''
          Using `${lib.showOption modulePath}.profiles.bookmarks.bookmarks` as an attribute set is deprecated and will be
          removed in a future release. Please use `${lib.showOption modulePath}.profiles.bookmarks.bookmarks.settings` with `${lib.showOption modulePath}.profiles.bookmarks.bookmarks.force = true` instead.

          Set `force = true` to acknowledge replacing existing custom bookmarks.

          Replace:
            ${lib.showOption modulePath}.profiles.bookmarks.bookmarks = { ... };

          With:
            ${lib.showOption modulePath}.profiles.bookmarks.bookmarks = {
              force = true;
              settings = { ... };
            };

        ''
      ];

      nmt.script = ''
        bookmarksUserJs=$(normalizeStorePaths \
          "home-files/${cfg.profilesPath}/bookmarks/user.js")

        assertFileContent \
          $bookmarksUserJs \
          ${./expected-bookmarks-user.js}

        bookmarksFile="$(sed -n \
          '/browser.bookmarks.file/ {s|^.*\(/nix/store[^"]*\).*|\1|;p}' \
          "$TESTED/home-files/${cfg.profilesPath}/bookmarks/user.js")"

        assertFileContent \
          $bookmarksFile \
          ${./expected-bookmarks-attrset.html}
      '';
    }
  );
}
