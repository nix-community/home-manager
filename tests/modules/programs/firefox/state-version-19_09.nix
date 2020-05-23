{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    home.stateVersion = "19.09";

    programs.firefox.enable = true;

    nixpkgs.overlays = [
      (self: super: {
        firefox-unwrapped = pkgs.runCommand "firefox-0" {
          meta.description = "I pretend to be Firefox";
          preferLocalBuild = true;
          allowSubstitutes = false;
        } ''
          mkdir -p "$out/bin"
          touch "$out/bin/firefox"
          chmod 755 "$out/bin/firefox"
        '';
      })
    ];

    nmt.script = ''
      assertFileRegex \
        $home_path/bin/firefox \
        MOZ_APP_LAUNCHER
    '';
  };
}
