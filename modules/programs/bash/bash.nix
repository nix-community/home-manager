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
        type = types.str;
        default = "$HOME/.bash_history";
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
        type = types.attrsOf types.str;
        example = { ll = "ls -l"; ".." = "cd .."; };
        description = ''
          An attribute set that maps aliases (the top level attribute names in
          this option) to command strings or directly to build outputs.
        '';
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

      logoutExtra = mkOption {
        default = "";
        type = types.lines;
        description = ''
          Extra commands that should be run when logging out of an
          interactive shell.
        '';
      };
    };
  };

  config = (
    let
      aliasesStr = concatStringsSep "\n" (
        mapAttrsToList (k: v: "alias ${k}=${escapeShellArg v}") cfg.shellAliases
      );

      shoptsStr = concatStringsSep "\n" (
        map (v: "shopt -s ${v}") cfg.shellOptions
      );

      sessionVarsStr = config.lib.shell.exportAll cfg.sessionVariables;

      historyControlStr =
        concatStringsSep "\n" (mapAttrsToList (n: v: "${n}=${v}") (
          {
            HISTFILE = "\"${cfg.historyFile}\"";
            HISTFILESIZE = toString cfg.historyFileSize;
            HISTSIZE = toString cfg.historySize;
          }
          // optionalAttrs (cfg.historyControl != []) {
            HISTCONTROL = concatStringsSep ":" cfg.historyControl;
          }
          // optionalAttrs (cfg.historyIgnore != []) {
            HISTIGNORE = concatStringsSep ":" cfg.historyIgnore;
          }
        ));
    in mkIf cfg.enable {
      programs.bash.bashrcExtra = ''
        # Commands that should be applied only for interactive shells.
        if [[ $- == *i* ]]; then
          ${historyControlStr}

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

        . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"

        ${sessionVarsStr}

        ${cfg.profileExtra}
      '';

      home.file.".bashrc".text = ''
        # -*- mode: sh -*-

        ${cfg.bashrcExtra}
      '';

      home.file.".bash_logout" = mkIf (cfg.logoutExtra != "") {
        text = ''
          # -*- mode: sh -*-

          ${cfg.logoutExtra}
        '';
      };

      home.packages =
        optional (cfg.enableAutojump) pkgs.autojump;
    }
  );
}
