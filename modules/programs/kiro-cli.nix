{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.kiro-cli;
in
{
  meta.maintainers = [ lib.hm.maintainers.superflash41 ];

  options.programs.kiro-cli = {
    enable = lib.mkEnableOption "kiro-cli, the command-line interface for Kiro";

    package = lib.mkPackageOption pkgs "kiro-cli" { };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs = {
      bash.initExtra = lib.mkIf cfg.enableBashIntegration (
        lib.mkMerge [
          (lib.mkBefore ''
            eval "$(${lib.getExe cfg.package} init bash pre)"
          '')
          (lib.mkAfter ''
            eval "$(${lib.getExe cfg.package} init bash post)"
          '')
        ]
      );

      zsh.initContent = lib.mkIf cfg.enableZshIntegration (
        lib.mkMerge [
          (lib.mkBefore ''
            eval "$(${lib.getExe cfg.package} init zsh pre)"
          '')
          (lib.mkAfter ''
            eval "$(${lib.getExe cfg.package} init zsh post)"
          '')
        ]
      );
    };
  };
}
