{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.granted;

in {
  meta.maintainers = [ hm.maintainers.wcarlsen ];

  options.programs.granted = {
    enable = mkEnableOption "granted";

    package = lib.mkPackageOption pkgs "granted" { };

    enableZshIntegration =
      lib.hm.shell.mkZshIntegrationOption { inherit config; };

    enableFishIntegration =
      lib.hm.shell.mkFishIntegrationOption { inherit config; };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.zsh.initContent = mkIf cfg.enableZshIntegration ''
      function assume() {
        export GRANTED_ALIAS_CONFIGURED="true"
        source ${cfg.package}/bin/assume "$@"
        unset GRANTED_ALIAS_CONFIGURED
      }
    '';

    programs.fish.functions.assume = mkIf cfg.enableFishIntegration ''
      set -x GRANTED_ALIAS_CONFIGURED "true"
      source ${cfg.package}/share/assume.fish $argv
      set -e GRANTED_ALIAS_CONFIGURED
    '';
  };
}
