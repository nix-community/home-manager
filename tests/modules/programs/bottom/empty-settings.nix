{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.bottom = {
      enable = true;
      package = pkgs.writeScriptBin "dummy" "";
    };

    nmt.script = ''
      assertPathNotExists home-files/.config/bottom
    '';
  };
}
