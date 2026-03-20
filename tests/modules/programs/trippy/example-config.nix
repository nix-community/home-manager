{
  programs.trippy = {
    enable = true;
    settings = {
      theme-colors = {
        bg-color = "black";
        border-color = "gray";
        text-color = "gray";
        tab-text-color = "green";
      };
      bindings = {
        toggle-help = "h";
        toggle-help-alt = "?";
        toggle-settings = "s";
        toggle-settings-tui = "1";
        toggle-settings-trace = "2";
        toggle-settings-dns = "3";
        toggle-settings-geoip = "4";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/trippy/trippy.toml
    assertFileContent home-files/.config/trippy/trippy.toml \
    ${./trippy.toml}
  '';
}
