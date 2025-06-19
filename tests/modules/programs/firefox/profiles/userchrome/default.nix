modulePath:
{ config, lib, pkgs, ... }:

let

  cfg = lib.getAttrFromPath modulePath config;

  firefoxMockOverlay = import ../../setup-firefox-mock-overlay.nix modulePath;
  dummyUserChromeText = builtins.readFile ./chrome/userChrome.css;
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
          userChrome = dummyUserChromeText;
        };
        file-text = {
          id = 2;
          userChrome.text = dummyUserChromeText;
        };
        source-file = {
          id = 3;
          userChrome.source = ./chrome/userChrome.css;
        };
        source-dir = {
          id = 4;
          userChrome.source = ./chrome;
        };
        source-drv-file = {
          id = 5;
          userChrome.source = config.lib.test.mkStubPackage {
            name = "wavefox-userchrome";
            buildScript = ''
              cp ${./chrome/userChrome.css} $out
            '';
          };
        };
        source-drv-dir = {
          id = 6;
          userChrome.source = config.lib.test.mkStubPackage {
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

          assertPathNotExists \
            home-files/${cfg.profilesPath}/lines/chrome/extraFile.css
          assertFileContent \
            home-files/${cfg.profilesPath}/lines/chrome/userChrome.css \
            ${./chrome/userChrome.css}

          assertPathNotExists \
            home-files/${cfg.profilesPath}/file-text/chrome/extraFile.css
          assertFileContent \
            home-files/${cfg.profilesPath}/file-text/chrome/userChrome.css \
            ${./chrome/userChrome.css}

          assertPathNotExists \
            home-files/${cfg.profilesPath}/source-file/chrome/extraFile.css
          assertFileContent \
            home-files/${cfg.profilesPath}/source-file/chrome/userChrome.css \
            ${./chrome/userChrome.css}

          assertFileExists \
            home-files/${cfg.profilesPath}/source-dir/chrome/extraFile.css
          assertFileContent \
            home-files/${cfg.profilesPath}/source-dir/chrome/userChrome.css \
            ${./chrome/userChrome.css}

          assertPathNotExists \
            home-files/${cfg.profilesPath}/source-drv-file/chrome/README.md
          assertFileContent \
            home-files/${cfg.profilesPath}/source-drv-file/chrome/userChrome.css \
            ${./chrome/userChrome.css}

          assertFileExists \
            home-files/${cfg.profilesPath}/source-drv-dir/chrome/README.md
          assertFileContent \
            home-files/${cfg.profilesPath}/source-drv-dir/chrome/userChrome.css \
            ${./chrome/userChrome.css}
        '';
    }
  );
}
