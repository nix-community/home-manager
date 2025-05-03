{ pkgs, lib, ... }:
{
  programs.lutris.enable = true;
  nmt.script =
    let
      wineRunnersDir = "home-files/.local/share/lutris/runners";
      runnersDir = "home-files/.config/lutris/runners";
    in
    ''
      assertPathNotExists ${wineRunnersDir}/proton
      assertPathNotExists ${wineRunnersDir}/wine
      assertPathNotExists ${runnersDir}
    '';
}
