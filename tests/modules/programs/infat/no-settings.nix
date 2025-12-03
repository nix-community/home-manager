{
  programs.infat.enable = true;

  test.stubs.infat = { };

  nmt.script =
    let
      expectedConfigPath = "home-files/.config/infat/config.toml";
    in
    ''
      assertPathNotExists "${expectedConfigPath}"
    '';
}
