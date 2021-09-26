{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.autojump.enable = true;

    test.stubs.autojump = {
      buildScript = "mkdir -p $out/bin; touch $out/bin/autojump";
    };

    nmt.script = ''
      assertFileExists home-path/bin/autojump
    '';
  };
}
