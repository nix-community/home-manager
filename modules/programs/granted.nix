{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.granted;
  package = pkgs.granted;

in {
  meta.maintainers = [ hm.maintainers.wcarlsen ];

  options.programs.granted = {
    enable = mkEnableOption "granted";

    enableZshIntegration =
      lib.hm.shell.mkZshIntegrationOption { inherit config; };
  };

  config = mkIf cfg.enable {
    home.packages = [ package ];

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      function assume() {
        export GRANTED_ALIAS_CONFIGURED="true"
        source ${package}/bin/assume "$@"
        unset GRANTED_ALIAS_CONFIGURED
      }
    '';
  };
}
