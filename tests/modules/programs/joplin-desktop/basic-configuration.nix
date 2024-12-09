{
  programs.joplin-desktop = {
    enable = true;
    sync = {
      target = "dropbox";
      interval = "10m";
    };
    extraConfig = {
      "richTextBannerDismissed" = true;
      "newNoteFocus" = "title";
    };
  };

  test.stubs.joplin-desktop = { };

  nmt.script = ''
    assertFileContains activate \
      '/home/hm-user/.config/joplin-desktop/settings.json'

    generated="$(grep -o '/nix/store/.*-joplin-settings.json' $TESTED/activate)"
    diff -u "$generated" ${./basic-configuration.json}
  '';
}
