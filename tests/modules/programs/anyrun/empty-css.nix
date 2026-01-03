{
  programs.anyrun = {
    enable = true;
    config.plugins = [ ];
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/anyrun/style.css
  '';
}
