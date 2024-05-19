{ pkgs, ... }:

let
  expectedConfDir =
    if pkgs.stdenv.isDarwin then "Library/Application Support" else ".config";
  expectedConfigPath = "home-files/${expectedConfDir}/jj/config.toml";
in {
  programs.jujutsu.enable = true;

  test.stubs.jujutsu = { };

  nmt.script = ''
    assertPathNotExists ${expectedConfigPath}
  '';
}
