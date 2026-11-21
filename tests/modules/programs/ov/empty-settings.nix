{
  programs.ov = {
    enable = true;
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/ov/config.yaml
  '';
}
