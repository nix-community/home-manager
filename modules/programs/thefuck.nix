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

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration shEvalCmd;
  };
}
