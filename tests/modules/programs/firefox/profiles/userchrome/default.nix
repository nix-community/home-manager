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
            "home-files/${cfg.profilesPath}/lines/chrome/userChrome.css" \
            ${./chrome/userChrome.css}

          assertFileContent \
            "home-files/${cfg.profilesPath}/file/chrome/userChrome.css" \
            ${./chrome/userChrome.css}

          assertPathNotExists \
            "home-files/${cfg.profilesPath}/derivation-file/chrome/extraFile.css"
          assertFileContent \
            "home-files/${cfg.profilesPath}/derivation-file/chrome/userChrome.css" \
            ${./chrome/userChrome.css}
        '';
    }
  );
}
