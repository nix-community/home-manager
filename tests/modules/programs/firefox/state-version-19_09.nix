modulePath:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = lib.getAttrFromPath modulePath config;

  firefoxMockOverlay = import ./setup-firefox-mock-overlay.nix modulePath;
in
{
  imports = [ firefoxMockOverlay ];

  config = lib.mkIf config.test.enableBig (
    {
      home.stateVersion = "19.09";
    }
    // lib.setAttrByPath modulePath {
      enable = true;
      configPath = ".mozilla/firefox";
    }
    // {
      nmt.script =
        let
          binPath =
            if pkgs.stdenv.hostPlatform.isDarwin then
              "Applications/${cfg.darwinAppName}.app/Contents/MacOS"
            else
              "bin";
        in
        ''
          assertFileRegex \
            "home-path/${binPath}/${cfg.finalPackage.meta.mainProgram}" \
            MOZ_APP_LAUNCHER
        '';
    }
  );
}
