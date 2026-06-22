modulePath:
{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = lib.getAttrFromPath modulePath config;

  firefoxMockOverlay = import ../../setup-firefox-mock-overlay.nix modulePath;

  darwinPath = "Applications/${cfg.darwinAppName}.app/Contents/Resources";
in
{
  imports = [ firefoxMockOverlay ];

  config = lib.mkIf config.test.enableBig (
    lib.setAttrByPath modulePath {
      enable = true;
      configPath = lib.mkIf pkgs.stdenv.hostPlatform.isLinux ".mozilla/firefox";
      profiles.bookmarks = {
        settings = {
          "general.smoothScroll" = false;
        };
        bookmarks = {
          force = true;
          settings = [
            {
              toolbar = true;
              bookmarks = [
                {
                  name = "Home Manager";
                  url = "https://wiki.nixos.org/wiki/Home_Manager";
                }
              ];
            }
            {
              name = "kernel.org";
              url = "https://www.kernel.org";
            }
            "separator"
            {
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
            }
            {
              name = "wikipedia";
              tags = [ "wiki" ];
              keyword = "wiki";
              url = "https://en.wikipedia.org/wiki/Special:Search?search=%s&go=Go";
            }
          ];
        };
      };
    }
    // {
      nmt.script =
        let
          libDir =
            if pkgs.stdenv.hostPlatform.isDarwin then
              "${cfg.finalPackage}/${darwinPath}"
            else
              "${cfg.finalPackage}/lib/${cfg.finalPackage.unwrapped.libName or cfg.wrappedPackageName}";
          config_file = "${libDir}/distribution/policies.json";
          config_file_browser = "${libDir}/browser/distribution/policies.json";
        in
        ''
          if [[ -f "${config_file}" ]]; then
            config_file="${config_file}"
          elif [[ -f "${config_file_browser}" ]]; then
            config_file="${config_file_browser}"
          else
            fail "Expected ${libDir}/distribution/policies.json to exist but it was not found."
          fi

          assertFileExists "${config_file}"

          noDefaultBookmarks_actual_value="$(${lib.getExe pkgs.jq} ".policies.NoDefaultBookmarks" ${config_file})"

          if [[ $noDefaultBookmarks_actual_value != "false" ]]; then
            fail "Expected '${config_file}' to set 'policies.NoDefaultBookmarks' to false"
          fi

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
            ${./expected-bookmarks-list.html}
        '';
    }
  );
}
