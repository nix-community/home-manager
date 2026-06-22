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

in
{
  imports = [ firefoxMockOverlay ];

  config = lib.mkIf config.test.enableBig (
    lib.setAttrByPath modulePath {
      enable = true;
      profiles = {
        basic.isDefault = true;
        test = {
          id = 1;
          settings = {
            "browser.bookmarks.file" = ./bookmarks.html;
            "general.smoothScroll" = false;
            "browser.newtabpage.pinned" = [
              {
                title = "NixOS";
                url = "https://nixos.org";
              }
            ];
          };
        };
      };
    }
    // {
      nmt.script =
        let
          binPath =
            if pkgs.stdenv.hostPlatform.isDarwin then
              "Applications/${cfg.darwinAppName}.app/Contents/MacOS"
            else
              "bin";
          expectedUserJs = pkgs.writeText "expected-user.js" (builtins.readFile ./expected-user.js + "\n");
        in
        ''
          assertFileRegex \
            "home-path/${binPath}/${cfg.finalPackage.meta.mainProgram}" \
            MOZ_APP_LAUNCHER

          assertDirectoryExists "home-files/${cfg.profilesPath}/basic"

          settingsUserJs=$(normalizeStorePaths \
            "home-files/${cfg.profilesPath}/test/user.js")

          assertFileContent \
            "$settingsUserJs" \
            ${expectedUserJs}
        '';
    }
  );
}
