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
      profiles.test.settings."general.smoothScroll" = false;
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

    test.asserts.warnings.expected = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      ''
        The default value of `programs.firefox.configPath` has changed from `".mozilla/firefox"` to `"''${config.xdg.configHome}/mozilla/firefox"`.
        You are currently using the legacy default (`".mozilla/firefox"`) because `home.stateVersion` is less than "26.05".
        To silence this warning and keep legacy behavior, set:
          programs.firefox.configPath = ".mozilla/firefox";
        To adopt the new default behavior, set:
          programs.firefox.configPath = "''${config.xdg.configHome}/mozilla/firefox";

        To migrate to the XDG path, move `~/.mozilla/firefox` to
        `$XDG_CONFIG_HOME/mozilla/firefox` and remove the old directory.
        Native messaging hosts are not moved by this option change.
      ''
    ];
  };
}
