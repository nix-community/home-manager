{
  programs.fuzzel.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.config/fuzzel
  '';
}
