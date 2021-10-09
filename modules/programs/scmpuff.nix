{ config, lib, pkgs, ... }:
with lib;
let cfg = config.programs.scmpuff;
in {
  meta.maintainers = [ maintainers.cpcloud ];

  options.programs.scmpuff = {
    enable = mkEnableOption ''
      scmpuff, a command line tool that allows you to work quicker with Git by
      substituting numeric shortcuts for files'';

    package = mkOption {
      type = types.package;
      default = pkgs.scmpuff;
      defaultText = literalExpression "pkgs.scmpuff";
      description = "Package providing the <command>scmpuff</command> tool.";
    };

    enableBashIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Bash integration.
      '';
    };

    enableZshIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Zsh integration.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      eval "$(${cfg.package}/bin/scmpuff init -s)"
    '';

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      eval "$(${cfg.package}/bin/scmpuff init -s)"
    '';
  };
}
