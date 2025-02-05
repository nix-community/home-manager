{ pkgs, ... }:

let
  configDir =
    if pkgs.stdenv.isDarwin then "Library/Application Support" else ".config";
in {
  programs.jujutsu.enable = true;

  nmt.script = ''
    assertPathNotExists 'home-files/${configDir}/jj/config.toml'
  '';
}
