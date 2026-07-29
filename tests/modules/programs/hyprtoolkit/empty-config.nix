{
  programs.hyprtoolkit.enable = true;

  nmt.script = ''
    assertPathNotExists "home-files/.config/hypr"
  '';
}
