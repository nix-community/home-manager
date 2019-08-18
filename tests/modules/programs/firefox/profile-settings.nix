{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.firefox = {
      enable = true;
      profiles.test.settings = {
        "general.smoothScroll" = false;
      };
    };

    nmt.script = ''
      assertFileRegex \
        home-path/bin/firefox \
        MOZ_APP_LAUNCHER

      assertFileContent \
        home-files/.mozilla/firefox/test/user.js \
        ${./profile-settings-expected-user.js}
    '';
  };
}
