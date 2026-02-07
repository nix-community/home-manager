{
  programs.crush = {
    enable = true;
    settings = { };
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/crush/crush.json
  '';
}
