{
  home.stateVersion = "18.09";

  programs.beets.settings = {
    directory = "~/Music";
  };

  nmt.script = ''
    assertFileExists home-files/.config/beets/config.yaml
    assertFileContains home-files/.config/beets/config.yaml 'directory: ~/Music'
  '';
}
