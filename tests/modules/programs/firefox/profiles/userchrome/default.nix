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
      profiles = {
        basic.isDefault = true;
        lines = {
          id = 1;
          userChrome = # CSS
            ''
              #urlbar {
                min-width: none !important;
                border: none !important;
                outline: none !important;
              }
            '';
        };
        path = {
          id = 2;
          userChrome = ./chrome/userChrome.css;
        };
        folder = {
          id = 3;
          userChrome = ./chrome;
        };
      };
    }
    // {
      nmt.script = ''
        assertFileRegex \
          home-path/bin/${cfg.wrappedPackageName} \
          MOZ_APP_LAUNCHER

        assertDirectoryExists home-files/${cfg.configPath}/basic

        assertFileContent \
          home-files/${cfg.configPath}/lines/chrome/userChrome.css \
          ${./expected-userchrome.css}

        assertFileContent \
          home-files/${cfg.configPath}/path/chrome/userChrome.css \
          ${./expected-userchrome.css}

        assertFileContent \
          home-files/${cfg.configPath}/folder/chrome/userChrome.css \
          ${./expected-userchrome.css}
      '';
    }
  );
}
