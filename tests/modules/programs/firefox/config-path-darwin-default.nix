{
  expectedDarwinPath,
  packageIsNull ? false,
  stateVersion,
}:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.firefox;

  firefoxMockOverlay = import ./setup-firefox-mock-overlay.nix [
    "programs"
    "firefox"
  ];

  expectedConfigPath =
    if pkgs.stdenv.hostPlatform.isDarwin then expectedDarwinPath else ".config/mozilla/firefox";
in
{
  imports = [ firefoxMockOverlay ];

  config = lib.mkIf config.test.enableBig {
    home.stateVersion = stateVersion;

    programs.firefox = {
      enable = true;
      profiles.test.settings."general.smoothScroll" = false;
    }
    // lib.optionalAttrs packageIsNull { package = null; };

    assertions = [
      {
        assertion = cfg.configPath == expectedConfigPath;
        message = "Firefox configPath has an unexpected default";
      }
    ];
  };
}
