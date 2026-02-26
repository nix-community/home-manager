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
      # The station below tests the additional configuration options.
      {
        name = "DEF CON Radio (SomaFM)";
        url = "https://somafm.com/defcon256.pls";
        buffering.seconds = 10;
        volume = 85;
        encoding = "utf-8";
        iconUrl = "https://somafm.com/img3/defcon400.png";
        forceHttp = true;
      }
    ];
  };

  nmt.script = ''
    assertFileContent "home-files/.config/pyradio/stations.csv" ${./expected-stations.csv}
  '';
}
