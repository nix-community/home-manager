{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.pazi;

in

{
  meta.maintainers = [ maintainers.marsam ];

  options.programs.pazi = {
    enable = mkEnableOption "pazi";

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

    enableFishIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Fish integration.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.pazi ];

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      eval "$(${pkgs.pazi}/bin/pazi init bash)"
    '';

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      eval "$(${pkgs.pazi}/bin/pazi init zsh)"
    '';

    programs.fish.shellInit = mkIf cfg.enableFishIntegration ''
      ${pkgs.pazi}/bin/pazi init fish | source
    '';
  };
}
