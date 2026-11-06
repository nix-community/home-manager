{
  programs.mitos = {
    enable = true;
    package = null;
    settings.editor.line-number = "relative";
  };

  nmt.script = ''
    assertPathNotExists home-path/bin/ms
    assertFileContent \
      home-files/.config/mitos/config.toml \
      ${./null-package-expected.toml}
  '';
}
