{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.alacritty.enable = true;

    nmt.script = ''
      assertPathNotExists home-files/.config/alacritty
    '';
  };
}
