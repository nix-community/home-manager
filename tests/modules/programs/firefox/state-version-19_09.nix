modulePath:
{ config, lib, ... }:
let
  cfg = lib.getAttrFromPath modulePath config;

  firefoxMockOverlay = import ./setup-firefox-mock-overlay.nix modulePath;
in {
  imports = [ firefoxMockOverlay ];

  config = lib.mkIf config.test.enableBig ({
    home.stateVersion = "19.09";
  } // lib.setAttrByPath modulePath { enable = true; } // {
    nmt.script = ''
      assertFileRegex \
        home-path/bin/${cfg.wrappedPackageName} \
        MOZ_APP_LAUNCHER
    '';
  });
}
