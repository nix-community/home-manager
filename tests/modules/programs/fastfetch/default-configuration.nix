{
  programs.fastfetch.enable = true;

  nmt.script = ''
    assertPathNotExists "home-files/.config/fastfetch/config.jsonc"
  '';
}
