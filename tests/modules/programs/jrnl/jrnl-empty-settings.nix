{
  programs.jrnl = {
    enable = true;
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/jrnl/jrnl.yaml
  '';
}
