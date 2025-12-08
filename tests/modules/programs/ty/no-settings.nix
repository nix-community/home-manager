{ pkgs, ... }:

{
  programs.ty = {
    enable = true;
  };

  test.stubs.ty = { };

  nmt.script =
    let
      expectedConfigPath = "home-files/.config/ty/ty.toml";
    in
    ''
      assertPathNotExists "${expectedConfigPath}"
    '';
}
