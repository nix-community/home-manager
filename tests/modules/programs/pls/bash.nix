{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs = {
      bash.enable = true;

      pls = {
        enable = true;
        enableAliases = true;
        package = config.lib.test.mkStubPackage { outPath = "@pls@"; };
      };
    };

    test.stubs.pls = { };

    nmt.script = ''
      assertFileExists home-files/.bashrc
      assertFileContains \
        home-files/.bashrc \
        "alias ls=@pls@/bin/pls"
      assertFileContains \
        home-files/.bashrc \
        "alias ll='@pls@/bin/pls -d perms -d user -d group -d size -d mtime -d git'"
    '';
  };
}
