{
  programs.wiremix = {
    enable = true;
    settings = {
      mouse = false;
      peaks = "auto";
      theme = "default";
      max_volume_percent = 100.0;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/wiremix/wiremix.toml
    assertFileContent home-files/.config/wiremix/wiremix.toml ${./expected.toml}
  '';
}
