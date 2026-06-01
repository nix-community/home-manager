{
  config,
  ...
}:

let
  cfg = config.programs.firefox;
in
{
  imports = [
    (import ./setup-firefox-mock-overlay.nix [
      "programs"
      "firefox"
    ])
  ];

  home.stateVersion = "26.05";

  programs.firefox = {
    enable = true;
    profiles.default.bookmarks = [
      {
        name = "Home Manager";
        url = "https://wiki.nixos.org/wiki/Home_Manager";
      }
    ];
  };

  test.asserts.warnings.expected = [
    ''
      Using `programs.firefox.profiles.default.bookmarks` as a list is deprecated and will be
      removed in a future release. Please use `programs.firefox.profiles.default.bookmarks.settings` with `programs.firefox.profiles.default.bookmarks.force = true` instead.

      Set `force = true` to acknowledge replacing existing custom bookmarks.

      Replace:
        programs.firefox.profiles.default.bookmarks = [ ... ];

      With:
        programs.firefox.profiles.default.bookmarks = {
          force = true;
          settings = [ ... ];
        };

    ''
  ];

  nmt.script = ''
    assertFileExists "home-files/${cfg.profilesPath}/default/user.js"
  '';
}
