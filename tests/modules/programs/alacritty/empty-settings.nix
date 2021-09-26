{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.alacritty.enable = true;

    test.stubs.alacritty = { };

    nmt.script = ''
      assertPathNotExists home-files/.config/alacritty
    '';
  };
}
