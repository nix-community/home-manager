{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ ./setup-firefox-mock-overlay.nix ];

  config = lib.mkIf config.test.enableBig {
    home.stateVersion = "19.09";

    programs.firefox.enable = true;

    nmt.script = ''
      assertFileRegex \
        home-path/bin/firefox \
        MOZ_APP_LAUNCHER
    '';
  };
}
