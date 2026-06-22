{
  home.stateVersion = "19.03";

  programs.beets.settings = {
    directory = "~/Music";
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/beets/config.yaml
  '';
}
