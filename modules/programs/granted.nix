{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.granted;
  package = pkgs.granted;

in {
  meta.maintainers = [ hm.maintainers.wcarlsen ];

  options.programs.granted = {
    enable = mkEnableOption "granted";

    enableZshIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Zsh integration.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ package ];

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      function assume() {
        export GRANTED_ALIAS_CONFIGURED="true"
        source ${package}/bin/.assume-wrapped "$@"
        unset GRANTED_ALIAS_CONFIGURED
      }
    '';
  };
}
