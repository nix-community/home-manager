{ ... }:
{
  programs.uv = {
    enable = true;
  };

  test.stubs.uv = { };

  nmt.script =
    let
      expectedConfigPath = "home-files/.config/uv/uv.toml";
    in
    ''
      assertPathNotExists "${expectedConfigPath}"
    '';
}
