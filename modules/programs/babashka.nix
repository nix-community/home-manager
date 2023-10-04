{ config, lib, pkgs, ... }:
with lib;
let cfg = config.programs.babashka;
in {
  meta.maintainers = [ maintainers.sohalt ];

  options = {
    programs.babashka = {
      enable = mkEnableOption "Babashka";
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
      home.packages = [ pkgs.babashka ];

      programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
        _bb_tasks() {
            COMPREPLY=( $(compgen -W "$(bb tasks |tail -n +3 |cut -f1 -d ' ')" -- ${
              COMP_WORDS [ COMP_CWORD ]
            }) );
        }
        # autocomplete filenames as well
        complete -f -F _bb_tasks bb
      '';

      programs.zsh.initExtraBeforeCompInit = mkIf cfg.enableZshIntegration ''
        _bb_tasks() {
          local matches=(`bb tasks |tail -n +3 |cut -f1 -d ' '`)
          compadd -a matches
          _files # autocomplete filenames as well
        }
        compdef _bb_tasks bb
      '';

      programs.fish.shellInit = mkIf cfg.enableFishIntegration ''
        function __bb_complete_tasks
          if not test "$__bb_tasks"
            set -g __bb_tasks (bb tasks |tail -n +3 |cut -f1 -d ' ')
          end

          printf "%s\n" $__bb_tasks
        end

        complete -c bb -a "(__bb_complete_tasks)" -d 'tasks'
      '';
    };
  };
}
