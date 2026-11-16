_:

{
  programs.poetry = {
    enable = true;
  };

  nmt.script =
    let
      expectedConfigPath = "home-files/.config/pypoetry/config.toml";
    in
    ''
      assertPathNotExists "${expectedConfigPath}"
    '';
}
