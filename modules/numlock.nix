{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.xsession.numlock;
in
  {
    options = {
      xsession.numlock.enable = mkEnableOption "Numlock";
    };

    config = mkIf (cfg.enable) {

      xsession.profileExtra = ''
        ${pkgs.numlockx}/bin/numlockx
      '';
    };
  }
