{
  programs = {
    jujutsu = {
      enable = true;
      package = null;
    };
    oyui = {
      enable = true;
      package = null;
      enableJujutsuIntegration = true;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/jj/config.toml
    assertFileContains home-files/.config/jj/config.toml 'diff-editor = "oyui"'
    assertFileContains home-files/.config/jj/config.toml '[merge-tools.oyui]'
  '';
}
