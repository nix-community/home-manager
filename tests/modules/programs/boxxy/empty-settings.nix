{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.boxxy.enable = true;

    nmt.script = ''
      assertPathNotExists home-files/.config/boxxy
    '';
  };
}
