{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.xsession.numlock;
in
  {
    options = {
      xsession.numlock.enable = mkEnableOption "Num Lock";
    };

    config = mkIf (cfg.enable) {

      xsession.profileExtra = ''
        ${pkgs.numlockx}/bin/numlockx
      '';
    };
  }
