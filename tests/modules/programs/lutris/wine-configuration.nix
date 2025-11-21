{ pkgs, lib, ... }:
{
  programs.lutris = {
    enable = true;
    protonPackages = with pkgs; [ proton-ge-bin ];
    winePackages = with pkgs; [ wineWow64Packages.full ];
  };

  nmt.script =
    let
      runnersDir = "home-files/.local/share/lutris/runners";
    in
    ''
      assertFileExists ${runnersDir}/proton/${lib.toLower pkgs.proton-ge-bin.steamcompattool.name}/proton
      assertFileExists ${runnersDir}/wine/${lib.toLower pkgs.wineWow64Packages.name}/bin/wine
    '';
}
