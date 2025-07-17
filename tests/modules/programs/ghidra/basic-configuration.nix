{ config, ... }:

{
  config = {
    programs.ghidra = {
      enable = true;
      gdb = true;
    };

    nmt.script = ''
      gdbConfigDir=home-files/.config/gdb
      assertFileExists $configDir/gdbinit.d/ghidra-modules.gdb
    '';
  };
}
