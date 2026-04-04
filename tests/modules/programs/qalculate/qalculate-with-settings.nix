{
  programs.qalculate = {
    enable = true;
    settings = {
      General = {
        colorize = 1;
        precision = 10;
        save_mode_on_exit = 1;
      };
      Mode = {
        angle_unit = 1;
        number_base = 10;
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/qalculate/qalc.cfg
    assertFileContent \
      home-files/.config/qalculate/qalc.cfg \
      ${./qalculate-with-settings-expected}
  '';
}
