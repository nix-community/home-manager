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
          userChrome = ''
            /*
              This is a simple comment that should be written inside the `chrome/userChrome.css`
            */

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
        derivation = {
          id = 4;
          userChrome = config.lib.test.mkStubPackage {
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

        assertPathNotExists \
          home-files/${cfg.configPath}/lines/chrome/extraFile.css
        assertFileContent \
          home-files/${cfg.configPath}/lines/chrome/userChrome.css \
          ${./chrome/userChrome.css}

        assertPathNotExists \
          home-files/${cfg.configPath}/path/chrome/extraFile.css
        assertFileContent \
          home-files/${cfg.configPath}/path/chrome/userChrome.css \
          ${./chrome/userChrome.css}

        assertFileExists \
          home-files/${cfg.configPath}/folder/chrome/extraFile.css
        assertFileContent \
          home-files/${cfg.configPath}/folder/chrome/userChrome.css \
          ${./chrome/userChrome.css}

        assertFileExists \
          home-files/${cfg.configPath}/derivation/chrome/README.md
        assertFileContent \
          home-files/${cfg.configPath}/derivation/chrome/userChrome.css \
          ${./chrome/userChrome.css}
      '';
    }
  );
}
