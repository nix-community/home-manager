{
  config,
  pkgs,
  realPkgs,
  ...
}:
let
  mkLibretroCore =
    name:
    config.lib.test.mkStubPackage {
      buildScript = ''
        mkdir -p $out/lib/retroarch/cores
        touch $out/lib/retroarch/cores/${name}_libretro.so
      '';
      extraAttrs.libretroCore = "/lib/retroarch/cores";
    };
in
{
  test.stubs = {
    libretro = {
      extraAttrs = {
        mgba = mkLibretroCore "mgba";
        snes9x2010 = mkLibretroCore "snes9x2010";
      };
    };
    retroarch-bare = {
      extraAttrs = {
        inherit (realPkgs.retroarch-bare) wrapper;
      };
    };
  };
}
