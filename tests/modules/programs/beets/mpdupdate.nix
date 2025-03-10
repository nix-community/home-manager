{
  home.stateVersion = "23.05";

  programs.beets = {
    enable = true;
    mpdIntegration.enableUpdate = true;
  };

  nmt.script = ''
    assertFileExists home-files/.config/beets/config.yaml
    assertFileContent \
      home-files/.config/beets/config.yaml \
      ${./mpdupdate-expected.yaml}
  '';
}
