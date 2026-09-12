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

  nmt.script = ''
    assertFileContains activate \
      '/home/hm-user/.config/joplin-desktop/settings.json'

    assertFileContains activate \
      "if [[ -v VERBOSE ]]; then"

    assertFileContains activate \
      "Merging Nix-generated config into"

    assertFileContains activate \
      "if [[ -v DRY_RUN ]]; then"

    generated="$(grep -o '/nix/store/[^ ]*-joplin-settings.json' $TESTED/activate)"
    diff -u "$generated" ${./basic-configuration.json}
  '';
}
