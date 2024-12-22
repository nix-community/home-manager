{
  programs.joplin-desktop = {
    enable = true;
    general = {
      editor = "kate";
      language = "en_GB";
    };
    sync.interval = "10m";
    appearance = { theme = "dark"; };
    note = {
      resizeLargeImages = "alwaysAsk";
      newTodoFocus = "title";
      newNoteFocus = "title";
      saveGeoLocation = false;
      autoPairBraces = true;
    };
    markdown = {
      softbreaks = true;
      fountain = false;
    };
    extraConfig = {
      "richTextBannerDismissed" = true;
      "editor.codeView" = true;
      "spellChecker.languages" = [ "en-GB" "de-DE" "fr-FR" ];
    };
    profiles = { Default = { }; };
  };

  test.stubs.joplin-desktop = { };

  nmt.script = ''
    assertFileContains activate \
      '/home/hm-user/.config/joplin-desktop/settings.json'

    generated="$(grep -o '/nix/store/.*-joplin-settings.json' $TESTED/activate)"
    diff -u "$generated" ${./basic-configuration.json}
  '';
}
