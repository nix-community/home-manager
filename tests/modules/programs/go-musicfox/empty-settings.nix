{
  programs.go-musicfox = {
    enable = true;
  };

  nmt.script = ''
    assertPathNotExists "home-files/.config/go-musicfox/config.toml"
  '';
}
