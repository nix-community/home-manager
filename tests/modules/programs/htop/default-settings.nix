{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.htop.enable = true;
    programs.htop.settings = { color_scheme = 0; };

    nmt.script = ''
      assertFileExists home-files/.config/htop/htoprc
    '';
  };
}
