{ pkgs, ... }:
let
  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "home-files/Library/Application Support/audacity"
    else
      "home-files/.config/audacity";
in
{
  programs.audacity.enable = true;

  nmt.script = ''
    assertPathNotExists "${configDir}/audacity.cfg"
  '';
}
