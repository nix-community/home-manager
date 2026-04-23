{
  programs.qalculate = {
    enable = true;
    settings = { };
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/qalculate/qalc.cfg
  '';
}
