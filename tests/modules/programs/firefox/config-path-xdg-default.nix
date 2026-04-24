{
  config,
  lib,
  pkgs,
  ...
}:
let
  firefoxMockOverlay = import ./setup-firefox-mock-overlay.nix [
    "programs"
    "firefox"
  ];
in
{
  imports = [ firefoxMockOverlay ];

  config = lib.mkIf (config.test.enableBig && !pkgs.stdenv.hostPlatform.isDarwin) {
    home.stateVersion = "26.05";
    xdg.configHome = "/home/hm-user/.config-custom";

    programs.firefox = {
      enable = true;
      profiles.test.settings."general.smoothScroll" = false;
    };

    nmt.script = ''
      assertFileRegex \
        home-files/.config-custom/mozilla/firefox/test/user.js \
        'user_pref\("general\.smoothScroll", false\);'

      assertPathNotExists \
        home-files/.mozilla/firefox/test/user.js
    '';
  };
}
