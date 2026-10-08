{ config, ... }:
let
  fakeLutris = config.lib.test.mkStubPackage {
    name = "lutris";
    version = "0.5.22";
    extraAttrs.override = _: fakeLutris;
  };
in
{
  programs.lutris = {
    enable = true;
    package = fakeLutris;
  };

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
