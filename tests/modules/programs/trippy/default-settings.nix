{
  programs.trippy.enable = true;
  programs.zsh.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.config/trippy/trippy.toml
    assertFileNotRegex home-files/.zshrc 'alias -- trip='
  '';
}
