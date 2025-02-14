{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.abook.enable = true;

    nmt.script = ''
      assertPathNotExists home-files/.config/abook/abookrc
    '';
  };
}
