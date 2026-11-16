{
  services.copyq = {
    enable = true;
    settings = {
      disable_tray = true;
      hide_main_window = true;
      hide_tabs = true;
      hide_toolbar = true;
      autostart = false;
    };
  };

  nmt.script = ''
    assertConfig () {
      assertFileContains activate "copyq --start-server config $@"
    }

    assertConfig hide_main_window true
    assertConfig hide_tabs true
    assertConfig hide_toolbar true
    assertConfig autostart false
  '';
}
