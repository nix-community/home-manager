{ config, lib, pkgs, ... }:

with lib;

{
  meta.maintainers = [ maintainers.rycee ];

  options.programs = let
    description = ''
      Whether to enable integration with terminals using the VTE
      library. This will let the terminal track the current working
      directory.
    '';
  in {
    bash.enableVteIntegration = mkEnableOption "" // { inherit description; };

    zsh.enableVteIntegration = mkEnableOption "" // { inherit description; };
  };

  config = mkMerge [
    (mkIf config.programs.bash.enableVteIntegration {
      # Unfortunately we have to do a little dance here to fix two
      # problems with the upstream vte.sh file:
      #
      #  - It does `PROMPT_COMMAND="__vte_prompt_command"` which
      #    clobbers any previously assigned prompt command.
      #
      #  - Its `__vte_prompt_command` function runs commands that will
      #    overwrite the exit status of the command the user ran.
      programs.bash.initExtra = ''
        __HM_PROMPT_COMMAND="''${PROMPT_COMMAND:+''${PROMPT_COMMAND%;};}__hm_vte_prompt_command"
        . ${pkgs.vte}/etc/profile.d/vte.sh
        if [[ $(type -t __vte_prompt_command) = function ]]; then
          __hm_vte_prompt_command() {
            local old_exit_status=$?
            __vte_prompt_command
            return $old_exit_status
          }
          PROMPT_COMMAND="$__HM_PROMPT_COMMAND"
        fi
        unset __HM_PROMPT_COMMAND
      '';
    })

    (mkIf config.programs.zsh.enableVteIntegration {
      programs.zsh.initExtra = ''
        . ${pkgs.vte}/etc/profile.d/vte.sh
      '';
    })
  ];
}
