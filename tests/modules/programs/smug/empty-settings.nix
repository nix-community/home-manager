{
  programs.smug.enable = true;
  nmt.script = ''
    assertPathNotExists home-files/.config/smug
  '';
}
