{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.z-lua;

  aliases = {
    zz = "z -c"; # restrict matches to subdirs of $PWD
    zi = "z -i"; # cd with interactive selection
    zf = "z -I"; # use fzf to select in multiple matches
    zb = "z -b"; # quickly cd to the parent directory
    zh = "z -I -t ."; # fzf
  };

in {
  meta.maintainers = [ maintainers.marsam ];

  options.programs.z-lua = {
    enable = mkEnableOption "z.lua";

    options = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "enhanced" "once" "fzf" ];
      description = ''
        List of options to pass to z.lua.
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

    enableAliases = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Whether to enable recommended z.lua aliases.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.z-lua ];

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      eval "$(${pkgs.z-lua}/bin/z --init bash ${
        concatStringsSep " " cfg.options
      })"
    '';

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      eval "$(${pkgs.z-lua}/bin/z --init zsh ${
        concatStringsSep " " cfg.options
      })"
    '';

    programs.fish.shellInit = mkIf cfg.enableFishIntegration ''
      source (${pkgs.z-lua}/bin/z --init fish ${
        concatStringsSep " " cfg.options
      } | psub)
    '';

    programs.bash.shellAliases = mkIf cfg.enableAliases aliases;

    programs.zsh.shellAliases = mkIf cfg.enableAliases aliases;

    programs.fish.shellAliases = mkIf cfg.enableAliases aliases;
  };
}
