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

    enableFishIntegration =
      lib.hm.shell.mkFishIntegrationOption { inherit config; };
  };

  config = mkIf cfg.enable {
    home.packages = [ package ];

    programs.zsh.initContent = mkIf cfg.enableZshIntegration ''
      function assume() {
        export GRANTED_ALIAS_CONFIGURED="true"
        source ${package}/bin/assume "$@"
        unset GRANTED_ALIAS_CONFIGURED
      }
    '';

    programs.fish.functions.assume = mkIf cfg.enableFishIntegration ''
      set -x GRANTED_ALIAS_CONFIGURED "true"
      source ${package}/share/assume.fish $argv
      set -e GRANTED_ALIAS_CONFIGURED
    '';
  };
}
