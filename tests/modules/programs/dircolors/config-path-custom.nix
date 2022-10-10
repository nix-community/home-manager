{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.dircolors = {
      enable = true;

      configPath = "${config.xdg.configHome}/dircolors";
    };

    nmt.script = ''
      assertFileExists home-files/.config/dircolors
    '';
  };
}

