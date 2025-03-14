{ pkgs, ... }:

{
  programs.poetry = { enable = true; };

  nmt.script = let
    expectedConfDir =
      if pkgs.stdenv.isDarwin then "Library/Application Support" else ".config";
    expectedConfigPath = "home-files/${expectedConfDir}/pypoetry/config.toml";
  in ''
    assertPathNotExists "${expectedConfigPath}"
  '';
}
