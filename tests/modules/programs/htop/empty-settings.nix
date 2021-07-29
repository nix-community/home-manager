{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.htop.enable = true;

    nmt.script = ''
      assertPathNotExists home-files/.config/htop
    '';
  };
}
