{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.bash;

in

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    programs.bash = {
      enable = mkEnableOption "GNU Bourne-Again SHell";

      historySize = mkOption {
        type = types.int;
        default = 10000;
        description = "Number of history lines to keep in memory.";
      };

      historyFile = mkOption {
        type = types.path;
        default = ~/.bash_history;
        description = "Location of the bash history file.";
      };

      historyFileSize = mkOption {
        type = types.int;
        default = 100000;
        description = "Number of history lines to keep on file.";
      };

      historyControl = mkOption {
        type = types.listOf (types.enum [
          "erasedups"
          "ignoredups"
          "ignorespace"
        ]);
        default = [];
        description = "Controlling how commands are saved on the history list.";
      };

      historyIgnore = mkOption {
        type = types.listOf types.str;
        default = [];
        example = [ "ls" "cd" "exit" ];
        description = "List of commands that should not be saved to the history list.";
      };

      shellOptions = mkOption {
        type = types.listOf types.str;
        default = [
          # Append to history file rather than replacing it.
          "histappend"

          # check the window size after each command and, if
          # necessary, update the values of LINES and COLUMNS.
          "checkwinsize"

          # Extended globbing.
          "extglob"
          "globstar"

          # Warn if closing shell with running jobs.
          "checkjobs"
        ];
        description = "Shell options to set.";
      };

      sessionVariables = mkOption {
        default = {};
        type = types.attrs;
        example = { MAILCHECK = 30; };
        description = ''
          Environment variables that will be set for the Bash session.
        '';
      };

      shellAliases = mkOption {
        default = {};
        example = { ll = "ls -l"; ".." = "cd .."; };
        description = ''
          An attribute set that maps aliases (the top level attribute names in
          this option) to command strings or directly to build outputs. The
          aliases are added to all users' shells.
        '';
        type = types.attrs;
      };

      enableAutojump = mkOption {
        default = false;
        type = types.bool;
        description = "Enable the autojump navigation tool.";
      };

      profileExtra = mkOption {
        default = "";
        type = types.lines;
        description = ''
          Extra commands that should be run when initializing a login
          shell.
        '';
      };

      bashrcExtra = mkOption {
        # Hide for now, may want to rename in the future.
        visible = false;
        default = "";
        type = types.lines;
        description = ''
          Extra commands that should be added to
          <filename>~/.bashrc</filename>.
        '';
      };

      initExtra = mkOption {
        default = "";
        type = types.lines;
        description = ''
          Extra commands that should be run when initializing an
          interactive shell.
        '';
      };
    };
  };

  config = (
    let
      aliasesStr = concatStringsSep "\n" (
        mapAttrsToList (k: v: "alias ${k}='${v}'") cfg.shellAliases
      );

      shoptsStr = concatStringsSep "\n" (
        map (v: "shopt -s ${v}") cfg.shellOptions
      );

      export = n: v: "export ${n}=\"${toString v}\"";
      setIfNonEmpty = n: v: optionalString (v != "") "${n}=${toString v}";

      histControlStr = concatStringsSep ":" cfg.historyControl;
      histIgnoreStr = concatStringsSep ":" cfg.historyIgnore;

      # If Bash is the session variable setter then this is the
      # attribute set of global session variables, otherwise it is an
      # empty set.
      globalEnvVars =
        optionalAttrs
          (config.home.sessionVariableSetter == "bash")
          config.home.sessionVariables;

      envVarsStr = concatStringsSep "\n" (
        mapAttrsToList export (cfg.sessionVariables // globalEnvVars)
      );
    in mkIf cfg.enable {
      programs.bash.bashrcExtra = ''
        # Commands that should be applied only for interactive shells.
        if [[ -n $PS1 ]]; then
          HISTSIZE=${toString cfg.historySize}
          HISTFILE=${toString cfg.historyFile}
          HISTFILESIZE=${toString cfg.historyFileSize}
          ${setIfNonEmpty "HISTCONTROL" histControlStr}
          ${setIfNonEmpty "HISTIGNORE" histIgnoreStr}

          ${shoptsStr}

          ${aliasesStr}

          ${cfg.initExtra}

          ${optionalString cfg.enableAutojump
            ". ${pkgs.autojump}/share/autojump/autojump.bash"}
        fi
      '';

      home.file.".bash_profile".text = ''
        # -*- mode: sh -*-

        # include .profile if it exists
        [[ -f ~/.profile ]] && . ~/.profile

        # include .bashrc if it exists
        [[ -f ~/.bashrc ]] && . ~/.bashrc
      '';

      home.file.".profile".text = ''
        # -*- mode: sh -*-

        ${envVarsStr}

        ${cfg.profileExtra}
      '';

      home.file.".bashrc".text = ''
        # -*- mode: sh -*-

        ${cfg.bashrcExtra}
      '';

      home.packages =
        optional (cfg.enableAutojump) pkgs.autojump;
    }
  );
}
