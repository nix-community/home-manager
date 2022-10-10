{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.dircolors = { enable = true; };

    nmt.script = ''
      assertFileExists home-files/.dir_colors
    '';
  };
}

