{ config, pkgs, ... }:
{
  imports = [ ./stubs.nix ];

  programs.retroarch = {
    enable = true;
    cores = {
      mgba.enable = true;
      snes9x = {
        enable = true;
        package = pkgs.libretro.snes9x2010;
      };
      custom = {
        enable = true;
        package = config.lib.test.mkStubPackage {
          buildScript = ''
            mkdir -p $out/lib/retroarch/cores
            touch $out/lib/retroarch/cores/custom_libretro.so
          '';
          extraAttrs.libretroCore = "/lib/retroarch/cores";
        };
      };
    };
  };

  nmt.script = ''
    assertFileExists home-path/bin/retroarch
    assertFileRegex home-path/bin/retroarch 'L.*lib/retroarch/cores'

    assertFileExists home-path/lib/retroarch/cores/mgba_libretro.so
    assertFileExists home-path/lib/retroarch/cores/snes9x2010_libretro.so
    assertFileExists home-path/lib/retroarch/cores/custom_libretro.so
  '';
}
