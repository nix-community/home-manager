{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.powerline-go;

  # Convert an option value to a string to be passed as argument to
  # powerline-go:
  valueToString = value:
    if builtins.isList value then
      builtins.concatStringsSep "," (builtins.map valueToString value)
    else if builtins.isAttrs value then
      valueToString
      (mapAttrsToList (key: val: "${valueToString key}=${valueToString val}")
        value)
    else
      builtins.toString value;

  modulesArgument = optionalString (cfg.modules != null)
    "-modules ${valueToString cfg.modules}";

  newlineArgument = optionalString cfg.newline "-newline";

  pathAliasesArgument = optionalString (cfg.pathAliases != null)
    "-path-aliases ${valueToString cfg.pathAliases}";

  otherSettingPairArgument = name: value:
    if value == true then "-${name}" else "-${name} ${valueToString value}";

  otherSettingsArgument = optionalString (cfg.settings != { })
    (concatStringsSep " "
      (mapAttrsToList otherSettingPairArgument cfg.settings));

  commandLineArguments = ''
    ${modulesArgument} ${newlineArgument} ${pathAliasesArgument} ${otherSettingsArgument}
  '';

in {
  meta.maintainers = [ maintainers.DamienCassou ];

  options = {
    programs.powerline-go = {
      enable = mkEnableOption
        "Powerline-go, a beautiful and useful low-latency prompt for your shell";

      modules = mkOption {
        default = null;
        type = types.nullOr (types.listOf types.str);
        description = ''
          List of module names to load. The list of all available
          modules as well as the choice of default ones are at
          <link xlink:href="https://github.com/justjanne/powerline-go"/>.
        '';
        example = [ "host" "ssh" "cwd" "gitlite" "jobs" "exit" ];
      };

      newline = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Set to true if the prompt should be on a line of its own.
        '';
        example = true;
      };

      pathAliases = mkOption {
        default = null;
        type = types.nullOr (types.attrsOf types.str);
        description = ''
          Pairs of full-path and corresponding desired short name. You
          may use '~' to represent your home directory but you should
          protect it to avoid shell substitution.
        '';
        example = literalExpression ''
          { "\\~/projects/home-manager" = "prj:home-manager"; }
        '';
      };

      settings = mkOption {
        default = { };
        type = with types; attrsOf (oneOf [ bool int str (listOf str) ]);
        description = ''
          This can be any key/value pair as described in
          <link xlink:href="https://github.com/justjanne/powerline-go"/>.
        '';
        example = literalExpression ''
          {
            hostname-only-if-ssh = true;
            numeric-exit-codes = true;
            cwd-max-depth = 7;
            ignore-repos = [ "/home/me/big-project" "/home/me/huge-project" ];
          }
        '';
      };

      extraUpdatePS1 = mkOption {
        default = "";
        description = "Shell code to execute after the prompt is set.";
        example = ''
          PS1=$PS1"NixOS> ";
        '';
        type = types.str;
      };
    };
  };

  config = {
    programs.bash.initExtra =
      mkIf (cfg.enable && config.programs.bash.enable) ''
        function _update_ps1() {
          local old_exit_status=$?
          PS1="$(${pkgs.powerline-go}/bin/powerline-go -error $old_exit_status ${commandLineArguments})"
          ${cfg.extraUpdatePS1}
          return $old_exit_status
        }

        if [ "$TERM" != "linux" ]; then
          PROMPT_COMMAND="_update_ps1;$PROMPT_COMMAND"
        fi
      '';

    programs.zsh.initExtra = mkIf (cfg.enable && config.programs.zsh.enable) ''
      function powerline_precmd() {
        PS1="$(${pkgs.powerline-go}/bin/powerline-go -error $? -shell zsh ${commandLineArguments})"
        ${cfg.extraUpdatePS1}
      }

      function install_powerline_precmd() {
        for s in "$\{precmd_functions[@]}"; do
          if [ "$s" = "powerline_precmd" ]; then
            return
          fi
        done
        precmd_functions+=(powerline_precmd)
      }

      if [ "$TERM" != "linux" ]; then
        install_powerline_precmd
      fi
    '';

    # https://github.com/justjanne/powerline-go#fish
    programs.fish.interactiveShellInit =
      mkIf (cfg.enable && config.programs.fish.enable) ''
        function fish_prompt
            eval ${pkgs.powerline-go}/bin/powerline-go -error $status -jobs (count (jobs -p)) ${commandLineArguments}
            ${cfg.extraUpdatePS1}
        end
      '';
  };
}
