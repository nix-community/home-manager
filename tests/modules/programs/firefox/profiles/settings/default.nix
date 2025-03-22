modulePath:
{ config, lib, pkgs, ... }:

let

  cfg = lib.getAttrFromPath modulePath config;

  firefoxMockOverlay = import ../../setup-firefox-mock-overlay.nix modulePath;

in {
  imports = [ firefoxMockOverlay ];

  config = lib.mkIf config.test.enableBig (lib.setAttrByPath modulePath {
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
    nmt.script = let
      isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
      profilePath = if isDarwin then
        "Library/Application Support/Firefox/Profiles"
      else
        ".mozilla/firefox";
    in ''
      assertDirectoryExists "home-files/${profilePath}/basic"

      assertFileContent \
        "home-files/${profilePath}/test/user.js" \
        ${./expected-user.js}
    '';
  });
}
