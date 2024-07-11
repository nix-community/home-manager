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
