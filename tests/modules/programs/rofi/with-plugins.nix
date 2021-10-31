{ config, lib, pkgs, ... }:

{
  config = {
    programs.rofi = {
      enable = true;
      plugins = [ pkgs.rofi-calc ];
    };

    test.stubs = {
      rofi = { };
      rofi-calc = { };
    };
  };
}
