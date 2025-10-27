{
  programs.delta = {
    enable = true;
    enableJujutsuIntegration = false;
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/jj/config.toml
  '';
}
