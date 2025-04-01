{ config, lib, pkgs, ... }:
let cfg = config.programs.granted;
in {
  meta.maintainers = [ lib.hm.maintainers.wcarlsen ];

  options.programs.granted = {
    enable = lib.mkEnableOption "granted";

    package = lib.mkPackageOption pkgs "granted" { };

    enableZshIntegration =
      lib.hm.shell.mkZshIntegrationOption { inherit config; };

    enableFishIntegration =
      lib.hm.shell.mkFishIntegrationOption { inherit config; };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.zsh.initContent = lib.mkIf cfg.enableZshIntegration ''
      function assume() {
        export GRANTED_ALIAS_CONFIGURED="true"
        source ${cfg.package}/bin/assume "$@"
        unset GRANTED_ALIAS_CONFIGURED
      }
    '';

    programs.fish.functions.assume = lib.mkIf cfg.enableFishIntegration ''
      set -x GRANTED_ALIAS_CONFIGURED "true"
      source ${cfg.package}/share/assume.fish $argv
      set -e GRANTED_ALIAS_CONFIGURED
    '';
  };
}
