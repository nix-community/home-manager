{
  services.hyprscratch.enable = true;

  nmt.script = ''
    assertPathNotExists "home-files/.config/hypr"
  '';
}
