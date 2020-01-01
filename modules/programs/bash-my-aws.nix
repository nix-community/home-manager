{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.bash-my-aws;

in

{
  options.programs.bash-my-aws = {
    enable = mkEnableOption "bash-my-aws - CLI commands for AWS";

    enableBashIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Bash integration.
      '';
    };

  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.bash-my-aws ];

    home.file.".bash-my-aws".source = pkgs.bash-my-aws;
    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      if [[ :$SHELLOPTS: =~ :(vi|emacs): ]]; then
        . ${pkgs.bash-my-aws}/aliases
        . ${pkgs.bash-my-aws}/bash_completion.sh
      fi
    '';

  };
}
