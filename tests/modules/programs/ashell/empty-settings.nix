{
  programs.ashell = {
    enable = true;
    settings = { };
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/ashell/config.toml
  '';
}
