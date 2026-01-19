{
  programs.pyradio = {
    enable = true;
    stations = [
      {
        name = "DEF CON Radio (SomaFM)";
        url = "https://somafm.com/defcon256.pls";
      }
      # The stations below test the csv escaping functionality.
      {
        name = "DEF CON Radio, SomaFM";
        url = "https://somafm.com/defcon256.pls";
      }
      {
        name = "DEF CON Radio on \"SomaFM\"";
        url = "https://somafm.com/defcon256.pls";
      }
      {
        name = ''DEF CON Radio on "SomaFM"'';
        url = "https://somafm.com/defcon256.pls";
      }
    ];
  };

  nmt.script = ''
    assertFileContent "home-files/.config/pyradio/stations.csv" ${./expected-stations.csv}
  '';
}
