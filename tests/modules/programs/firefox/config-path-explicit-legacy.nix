{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.firefox;
  profilesPath = lib.removePrefix "${config.home.homeDirectory}/" cfg.profilesPath;

  firefoxMockOverlay = import ./setup-firefox-mock-overlay.nix [
    "programs"
    "firefox"
  ];
in
{
  imports = [ firefoxMockOverlay ];

  config = lib.mkIf config.test.enableBig {
    home.stateVersion = "25.11";

    programs.firefox = {
      enable = true;
      configPath = ".mozilla/firefox";
      profiles.test.settings."general.smoothScroll" = false;
    };

    test.asserts.warnings = {
      enable = true;
      expected = [ ];
    };

    nmt.script = ''
      assertFileRegex \
        "home-files/${profilesPath}/test/user.js" \
        'user_pref("general\.smoothScroll", false);'

      assertPathNotExists \
        "home-files/${
          if pkgs.stdenv.hostPlatform.isDarwin then
            ".config/mozilla/firefox/Profiles"
          else
            ".config/mozilla/firefox"
        }/test/user.js"
    '';
  };
}
