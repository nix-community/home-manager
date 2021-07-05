{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.autojump.enable = true;

    nmt.script = ''
      assertFileExists home-path/bin/autojump
    '';
  };
}
