{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.fish;

  abbrsStr = concatStringsSep "\n" (
    mapAttrsToList (k: v: "abbr --add ${k} '${v}'") cfg.shellAbbrs
  );

  aliasesStr = concatStringsSep "\n" (
    mapAttrsToList (k: v: "alias ${k}='${v}'") cfg.shellAliases
  );

in

{
  options = {
    programs.fish = {
      enable = mkEnableOption "fish friendly interactive shell";

      shellAliases = mkOption {
        default = {};
        description = ''
          Set of aliases for fish shell. See
          <option>environment.shellAliases</option> for an option
          format description.
        '';
        type = types.attrs;
      };

      shellAbbrs = mkOption {
        default = {};
        description = ''
          Set of abbreviations for fish shell.
        '';
        type = types.attrs;
      };

      shellInit = mkOption {
        default = "";
        description = ''
          Shell script code called during fish shell initialisation.
        '';
        type = types.lines;
      };

      loginShellInit = mkOption {
        default = "";
        description = ''
          Shell script code called during fish login shell initialisation.
        '';
        type = types.lines;
      };

      interactiveShellInit = mkOption {
        default = "";
        description = ''
          Shell script code called during interactive fish shell initialisation.
        '';
        type = types.lines;
      };

      promptInit = mkOption {
        default = "";
        description = ''
          Shell script code used to initialise fish prompt.
        '';
        type = types.lines;
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.fish ];

    xdg.configFile."fish/config.fish".text = ''
      # ~/.config/fish/config.fish: DO NOT EDIT -- this file has been generated automatically.
      # if we haven't sourced the general config, do it
      if not set -q __fish_general_config_sourced
        set fish_function_path ${pkgs.fish-foreign-env}/share/fish-foreign-env/functions $fish_function_path
        fenv source ${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh > /dev/null
        set -e fish_function_path[1]

        ${cfg.shellInit}
        # and leave a note so we don't source this config section again from
        # this very shell (children will source the general config anew)
        set -g __fish_general_config_sourced 1
      end
      # if we haven't sourced the login config, do it
      status --is-login; and not set -q __fish_login_config_sourced
      and begin

        ${cfg.loginShellInit}
        # and leave a note so we don't source this config section again from
        # this very shell (children will source the general config anew)
        set -g __fish_login_config_sourced 1
      end
      # if we haven't sourced the interactive config, do it
      status --is-interactive; and not set -q __fish_interactive_config_sourced
      and begin
        # Abbrs
        ${abbrsStr}

        # Aliases
        ${aliasesStr}

        ${cfg.promptInit}
        ${cfg.interactiveShellInit}
        # and leave a note so we don't source this config section again from
        # this very shell (children will source the general config anew,
        # allowing configuration changes in, e.g, aliases, to propagate)
        set -g __fish_interactive_config_sourced 1
      end
    '';
  };
}
