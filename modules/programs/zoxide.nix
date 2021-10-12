{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.zoxide;

in {
  meta.maintainers = [ maintainers.marsam ];

  options.programs.zoxide = {
    enable = mkEnableOption "zoxide";

    package = mkOption {
      type = types.package;
      default = pkgs.zoxide;
      defaultText = literalExpression "pkgs.zoxide";
      description = ''
        Zoxide package to install.
      '';
    };

    options = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--no-aliases" ];
      description = ''
        List of options to pass to zoxide.
      '';
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

    enableFishIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Fish integration.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      eval "$(${cfg.package}/bin/zoxide init bash ${
        concatStringsSep " " cfg.options
      })"
    '';

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      eval "$(${cfg.package}/bin/zoxide init zsh ${
        concatStringsSep " " cfg.options
      })"
    '';

    programs.fish.shellInit = mkIf cfg.enableFishIntegration ''
      ${cfg.package}/bin/zoxide init fish ${
        concatStringsSep " " cfg.options
      } | source
    '';
  };
}
