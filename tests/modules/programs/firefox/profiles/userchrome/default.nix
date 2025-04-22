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
        folder = {
          id = 3;
          chromeDir = ./chrome;
        };
        derivation-file = {
          id = 4;
          userChrome = pkgs.writeText "userChrome.css" (builtins.readFile ./chrome/userChrome.css);
        };
        derivation-folder = {
          id = 5;
          chromeDir = config.lib.test.mkStubPackage {
            name = "wavefox";
            buildScript = ''
              mkdir -p $out
              ln -s ${./chrome/userChrome.css} $out/userChrome.css
              echo test > $out/README.md
            '';
          };
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

        assertFileExists \
          home-files/${cfg.configPath}/folder/chrome/extraFile.css
        assertFileContent \
          home-files/${cfg.configPath}/folder/chrome/userChrome.css \
          ${./chrome/userChrome.css}

        assertPathNotExists \
          home-files/${cfg.configPath}/derivation-file/chrome/extraFile.css
        assertFileContent \
          home-files/${cfg.configPath}/derivation-file/chrome/userChrome.css \
          ${./chrome/userChrome.css}

        assertFileExists \
          home-files/${cfg.configPath}/derivation-folder/chrome/README.md
        assertFileContent \
          home-files/${cfg.configPath}/derivation-folder/chrome/userChrome.css \
          ${./chrome/userChrome.css}
      '';
    }
  );
}
