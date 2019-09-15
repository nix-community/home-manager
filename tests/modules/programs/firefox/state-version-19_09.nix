{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    home.stateVersion = "19.09";

    programs.firefox.enable = true;

    nmt.script = ''
      assertFileRegex \
        home-path/bin/firefox \
        MOZ_APP_LAUNCHER
    '';
  };
}
