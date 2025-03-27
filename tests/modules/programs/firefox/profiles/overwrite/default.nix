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
        id = 6;
        preConfig = ''
          user_pref("browser.search.suggest.enabled", false);
        '';
        settings = { "browser.search.suggest.enabled" = true; };
        extraConfig = ''
          user_pref("findbar.highlightAll", true);
        '';
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
