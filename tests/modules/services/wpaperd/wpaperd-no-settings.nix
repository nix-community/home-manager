{
  services.wpaperd = {
    enable = true;
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/wpaperd/wallpaper.toml
  '';
}
