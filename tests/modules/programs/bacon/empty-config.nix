{ pkgs, ... }:
let
  configDir = if pkgs.stdenv.isDarwin then
    "Library/Application Support/org.dystroy.bacon"
  else
    ".config/bacon";
in {
  programs.bacon.enable = true;

  test.stubs.bacon = { };

  nmt.script = ''
    assertPathNotExists 'home-files/${configDir}/prefs.toml'
  '';
}
