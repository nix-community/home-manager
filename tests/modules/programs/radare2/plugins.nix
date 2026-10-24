{ config, ... }:

let
  mkPlugin =
    name: files:
    config.lib.test.mkStubPackage {
      inherit name;
      buildScript = ''
        mkdir -p $out/lib/radare2/plugins
        ${builtins.concatStringsSep "\n" (
          map (
            f: "mkdir -p $(dirname $out/lib/radare2/plugins/${f}); touch $out/lib/radare2/plugins/${f}"
          ) files
        )}
      '';
    };
in
{
  programs.radare2 = {
    enable = true;
    plugins = [
      (mkPlugin "r2ghidra" [
        "libcore_r2ghidra.so"
        "r2ghidra_sleigh/x86.sla"
      ])
      (mkPlugin "r2frida" [ "libio_frida.so" ])
    ];
  };

  nmt.script = ''
    plugins=home-files/.local/share/radare2/plugins
    assertFileExists $plugins/libcore_r2ghidra.so
    assertFileExists $plugins/r2ghidra_sleigh/x86.sla
    assertFileExists $plugins/libio_frida.so
    assertPathNotExists home-files/.config/radare2
    assertPathNotExists home-files/.radare2rc

    # Per-file links keep the plugin directory writable for r2pm.
    [[ ! -L $TESTED/$plugins ]] || fail "plugin directory must not be a symlink"
  '';
}
