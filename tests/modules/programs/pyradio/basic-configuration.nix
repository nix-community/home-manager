{
  programs.pyradio = {
    enable = true;
    settings.enable_clock = true;
  };

  nmt.script = ''
    assertFileExists "home-files/.config/pyradio/config"
    assertFileContent "home-files/.config/pyradio/config" ${./expected-config}
  '';
}
