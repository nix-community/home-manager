{ config, lib, pkgs, ... }:
with lib;
let cfg = config.programs.thefuck;
in {
  meta.maintainers = [ hm.maintainers.ilaumjd ];

  options.programs.thefuck = {
    enable = mkEnableOption
      "thefuck - magnificent app that corrects your previous console command";

    package = mkPackageOption pkgs "thefuck" { };

    enableBashIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Bash integration.
      '';
    };

    enableFishIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Fish integration.
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
      eval "$(${cfg.package}/bin/thefuck --alias)"
    '';

    programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration (
      # Using mkAfter to make it more likely to appear after other
      # manipulations of the prompt.
      mkAfter ''
        ${cfg.package}/bin/thefuck --alias | source 
      '');

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      eval "$(${cfg.package}/bin/thefuck --alias)"
    '';
  };
}
