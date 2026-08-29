{
  programs.impala = {
    enable = true;
    settings = {
      access_point = {
        start = "n";
        stop = "x";
      };
      ascii = false;
      device = {
        infos = "i";
        toggle_power = "o";
      };
      esc_quit = false;
      mode = "station";
      station = {
        known_network = {
          remove = "d";
          share = "p";
          show_all = "a";
          toggle_autoconnect = "t";
        };
        new_network = {
          connect_hidden = "";
          show_all = "a";
        };
        toggle_scanning = "s";
      };
      switch = "r";
      theme = {
        background = "dark gray";
        border = "green";
        error_color = "red";
        hidden_color = "dark gray";
        info_color = "green";
        text_color = "white";
        warning_color = "yellow";
      };
    };
  };

  nmt.script = ''
    assertFileContent "home-files/.config/impala/config.toml" ${./expected-config.toml}
  '';
}
