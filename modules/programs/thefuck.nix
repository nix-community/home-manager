{ config, lib, pkgs, ... }:

with lib;

{
  meta.maintainers = [ hm.maintainers.ilaumjd ];

  options.programs.thefuck = {
    enable = mkEnableOption
      "thefuck - magnificent app that corrects your previous console command";

    package = mkPackageOption pkgs "thefuck" { };

    enableInstantMode = mkEnableOption "thefuck's experimental instant mode";

    enableBashIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Bash integration.
      '';
    };

    enableFishIntegration = mkEnableOption "Fish integration" // {
      default = true;
    };

    enableZshIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Zsh integration.
      '';
    };
  };

  config = let
    cfg = config.programs.thefuck;

    cliArgs = cli.toGNUCommandLineShell { } {
      alias = true;
      enable-experimental-instant-mode = cfg.enableInstantMode;
    };

    shEvalCmd = ''
      eval "$(${cfg.package}/bin/thefuck ${cliArgs})"
    '';
  in mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.bash.initExtra = mkIf cfg.enableBashIntegration shEvalCmd;

    programs.fish.functions = mkIf cfg.enableFishIntegration {
      fuck = {
        description = "Correct your previous console command";
        body = ''
          set -l fucked_up_command $history[1]
          env TF_SHELL=fish TF_ALIAS=fuck PYTHONIOENCODING=utf-8 ${cfg.package}/bin/thefuck $fucked_up_command THEFUCK_ARGUMENT_PLACEHOLDER $argv | read -l unfucked_command
          if [ "$unfucked_command" != "" ]
            eval $unfucked_command
            builtin history delete --exact --case-sensitive -- $fucked_up_command
            builtin history merge
          end
        '';
      };
    };

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration shEvalCmd;
  };
}
