{
  config,
  lib,
  pkgs,
  ...
}:
let
  mkRetroarchPackage =
    {
      cores,
      settings,
    }:
    let
      settingsFile = pkgs.writeText "declarative-retroarch.cfg" (
        lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value: ''${name} = "${value}"'') settings)
      );
    in
    config.lib.test.mkStubPackage {
      name = "retroarch";
      buildScript = ''
        mkdir -p $out/bin $out/lib/retroarch/cores
        cat > $out/bin/retroarch <<'EOF'
        #!/bin/sh
        # -L $out/lib/retroarch/cores
        exec retroarch --appendconfig ${settingsFile} "$@"
        EOF
        chmod 755 $out/bin/retroarch
        ${lib.concatMapStringsSep "\n" (core: ''
          ln -s ${core}${core.libretroCore}/* $out/lib/retroarch/cores/
        '') cores}
      '';
    };

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
        wrapper = mkRetroarchPackage;
      };
    };
  };
}
