{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.htop.enable = true;

    nmt.script = ''
      assertFileExists home-files/.config/htop/htoprc
    '';
  };
}
