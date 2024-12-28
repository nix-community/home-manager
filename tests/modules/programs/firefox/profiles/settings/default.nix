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
      basic.isDefault = true;
      test = {
        id = 1;
        settings = {
          "general.smoothScroll" = false;
          "browser.newtabpage.pinned" = [{
            title = "NixOS";
            url = "https://nixos.org";
          }];
        };
      };
    };
  } // {
    nmt.script = ''
      assertFileRegex \
        home-path/bin/${cfg.wrappedPackageName} \
        MOZ_APP_LAUNCHER

      assertDirectoryExists home-files/${cfg.configPath}/basic

      assertFileContent \
        home-files/${cfg.configPath}/test/user.js \
        ${./expected-user.js}
    '';
  });
}
