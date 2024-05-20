{
  programs.fastfetch.enable = true;

  test.stubs.fastfetch = { };

  nmt.script = ''
    assertPathNotExists "home-files/.config/fastfetch/config.jsonc"
  '';
}
