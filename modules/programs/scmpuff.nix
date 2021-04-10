{ config, lib, pkgs, ... }:
with lib;
let cfg = config.programs.scmpuff;
in {
  meta.maintainers = [ maintainers.cpcloud ];

  options.programs.scmpuff = {
    enable = mkEnableOption
      "Work with git from the command line quicker, by substituting numeric shortcuts for files.";

    package = mkOption {
      type = types.package;
      default = pkgs.gitAndTools.scmpuff;
      defaultText = literalExample "pkgs.gitAndTools.scmpuff";
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

    programs.bash.initExtra = mkIf (cfg.enable && cfg.enableBashIntegration) ''
      eval "$(${cfg.package}/bin/scmpuff init -s)"
    '';

    programs.zsh.initExtra = mkIf (cfg.enable && cfg.enableZshIntegration) ''
      eval "$(${cfg.package}/bin/scmpuff init -s)"
    '';
  };
}
