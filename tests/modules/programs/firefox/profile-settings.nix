{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.firefox = {
      enable = true;
      profiles.test.settings = { "general.smoothScroll" = false; };
    };

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

      assertFileContent \
        $home_files/.mozilla/firefox/test/user.js \
        ${./profile-settings-expected-user.js}
    '';
  };
}
