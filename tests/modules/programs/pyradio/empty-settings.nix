{
  programs.pyradio = {
    enable = true;
    settings = { };
  };

  nmt.script = ''
    assertPathNotExists "home-files/.config/pyradio/config"
    assertPathNotExists "home-files/.config/pyradio/stations.csv"
  '';
}
