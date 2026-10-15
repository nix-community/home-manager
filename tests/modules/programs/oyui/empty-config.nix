{ pkgs, ... }:
let
  configDir = if pkgs.stdenv.hostPlatform.isDarwin then "Library/Application Support" else ".config";
in
{
  programs.oyui = {
    enable = true;
    package = null;
  };

  nmt.script = ''
    assertPathNotExists home-files/${configDir}/oyui/config.rn
  '';
}
