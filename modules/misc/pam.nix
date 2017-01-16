{ config, lib, pkgs, ... }:

with lib;

let

  homeCfg = config.home;

in

{
  options = {};

  config = mkIf (homeCfg.sessionVariableSetter == "pam") {
    home.file.".pam_environment".text =
      concatStringsSep "\n" (
        mapAttrsToList (n: v: "${n} OVERRIDE=${v}") homeCfg.sessionVariables
      ) + "\n";
  };
}
