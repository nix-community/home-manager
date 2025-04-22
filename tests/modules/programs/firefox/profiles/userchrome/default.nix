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
        lines = {
          id = 1;
          userChrome = builtins.readFile ./chrome/userChrome.css;
        };
        file = {
          id = 2;
          userChrome = ./chrome/userChrome.css;
        };
        derivation-file = {
          id = 4;
          userChrome = pkgs.writeText "userChrome.css" (builtins.readFile ./chrome/userChrome.css);
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
          ${./chrome/userChrome.css}

        assertFileContent \
          home-files/${cfg.configPath}/file/chrome/userChrome.css \
          ${./chrome/userChrome.css}

        assertPathNotExists \
          home-files/${cfg.configPath}/derivation-file/chrome/extraFile.css
        assertFileContent \
          home-files/${cfg.configPath}/derivation-file/chrome/userChrome.css \
          ${./chrome/userChrome.css}
      '';
    }
  );
}
