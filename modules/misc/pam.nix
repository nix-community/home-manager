{ config, lib, pkgs, ... }:

with lib;

let

  homeCfg = config.home;

in

{
  meta.maintainers = [ maintainers.rycee ];

  options = {};

  config = mkIf (homeCfg.sessionVariableSetter == "pam") {
    home.file.".pam_environment".text =
      concatStringsSep "\n" (
        mapAttrsToList (n: v: "${n} OVERRIDE=${v}") homeCfg.sessionVariables
      ) + "\n";
  };
}
