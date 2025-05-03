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
            if pkgs.hostPlatform.isDarwin then
              "Applications/${cfg.darwinAppName}.app/Contents/MacOS"
            else
              "bin";
        in
        ''
          assertFileRegex \
            "home-path/${binPath}/${cfg.wrappedPackageName}" \
            MOZ_APP_LAUNCHER

          assertDirectoryExists "home-files/${cfg.profilesPath}/basic"

          assertFileContent \
            "home-files/${cfg.profilesPath}/test/user.js" \
            ${./expected-user.js}
        '';
    }
  );
}
