{ pkgs, ... }:

let
  configDir = if pkgs.stdenv.isDarwin then
    "home-files/Library/Application Support"
  else
    "home-files/.config";
in {
  programs.nheko.enable = true;

  nmt.script = ''
    assertPathNotExists "${configDir}/nheko/nheko.conf"
  '';
}
