{
  programs.jujutsu = {
    enable = true;
    package = null;
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/jj/config.toml
  '';
}
