{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.xsession.numlock;
in
  {
    options = {
      xsession.numlock.enable = mkEnableOption "Numlock";
    };

    config = mkIf (cfg != null) {

      xsession.profileExtra = ''
        ${pkgs.numlockx}/bin/numlockx
      '';
    };
  }
