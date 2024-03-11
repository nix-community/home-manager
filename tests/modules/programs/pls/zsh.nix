{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs = {
      zsh.enable = true;

      pls = {
        enable = true;
        enableAliases = true;
        package = config.lib.test.mkStubPackage { outPath = "@pls@"; };
      };
    };

    test.stubs = {
      pls = { };
      zsh = { };
    };

    nmt.script = ''
      assertFileExists home-files/.zshrc
      assertFileContains \
        home-files/.zshrc \
        "alias -- 'ls'='@pls@/bin/pls'"
      assertFileContains \
        home-files/.zshrc \
        "alias -- 'll'='@pls@/bin/pls -d perms -d user -d group -d size -d mtime -d git'"
    '';
  };
}
