{
  programs.wiremix = {
    enable = true;
    settings = {
      fps = 75.0;
      mouse = false;

      tabs = [
        "playback"
        "output"
        "input"
        "configuration"
      ];

      theme.default.selector.fg = "LightCyan";
      char_sets.extracompat.dropdown_selector = ">>";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/wiremix/wiremix.toml
    assertFileContent home-files/.config/wiremix/wiremix.toml ${./example-settings-expected.toml}
  '';
}
