{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.granted;

  # The assume script exports credentials into the calling shell, so it has
  # to be sourced. Bash and Zsh can share the same wrapper function.
  assumeFunction = ''
    function assume() {
      export GRANTED_ALIAS_CONFIGURED="true"
      source ${cfg.package}/bin/assume "$@"
      unset GRANTED_ALIAS_CONFIGURED
    }
  '';
in
{
  meta.maintainers = [ lib.maintainers.wcarlsen ];

  options.programs.granted = {
    enable = lib.mkEnableOption "granted";

    package = lib.mkPackageOption pkgs "granted" { };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.bash.initExtra = lib.mkIf cfg.enableBashIntegration assumeFunction;

    programs.zsh.initContent = lib.mkIf cfg.enableZshIntegration assumeFunction;

    programs.fish.functions.assume = lib.mkIf cfg.enableFishIntegration ''
      set -x GRANTED_ALIAS_CONFIGURED "true"
      source ${cfg.package}/share/assume.fish $argv
      set -e GRANTED_ALIAS_CONFIGURED
    '';
  };
}
