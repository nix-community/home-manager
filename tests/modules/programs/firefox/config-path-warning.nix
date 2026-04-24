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
    home.stateVersion = "25.11";

    programs.firefox = {
      enable = true;
      profiles.test.settings."general.smoothScroll" = false;
    };

    nmt.script = ''
      assertFileRegex \
        home-files/.mozilla/firefox/test/user.js \
        'user_pref\("general\.smoothScroll", false\);'

      assertPathNotExists \
        home-files/.config/mozilla/firefox/test/user.js
    '';

    test.asserts.warnings.expected = [
      ''
        The default value of `programs.firefox.configPath` has changed from `".mozilla/firefox"` to `"/home/hm-user/.config/mozilla/firefox"`.
        You are currently using the legacy default (`".mozilla/firefox"`) because `home.stateVersion` is less than "26.05".
        To silence this warning and keep legacy behavior, set:
        programs.firefox.configPath = ".mozilla/firefox";
        To adopt the new default behavior, set:
          programs.firefox.configPath = "/home/hm-user/.config/mozilla/firefox";

        To migrate to the XDG path, move `~/.mozilla/firefox` to
        `$XDG_CONFIG_HOME/mozilla/firefox` and remove the old directory.
        Native messaging hosts are not moved by this option change.
      ''
    ];
  };
}
