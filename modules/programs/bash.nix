{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.bash;

  writeBashScript = name: text:
    pkgs.writeTextFile {
      inherit name text;
      checkPhase = ''
        ${pkgs.stdenv.shellDryRun} "$target"
      '';
    };

in {
  meta.maintainers = [ maintainers.rycee ];

  imports = [
    (mkRenamedOptionModule [ "programs" "bash" "enableAutojump" ] [
      "programs"
      "autojump"
      "enable"
    ])
  ];

  options = {
    programs.bash = {
      enable = mkEnableOption "GNU Bourne-Again SHell";

      enableCompletion = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to enable Bash completion for all interactive Bash shells.

          Note, if you use NixOS or nix-darwin and do not have Bash completion
          enabled in the system configuration, then make sure to add

          ```nix
            environment.pathsToLink = [ "/share/bash-completion" ];
          ```

          to your system configuration to get completion for system packages.
          Note, the legacy {file}`/etc/bash_completion.d` path is
          not supported by Home Manager.
        '';
      };

      historySize = mkOption {
        type = types.int;
        default = 10000;
        description = "Number of history lines to keep in memory.";
      };

      historyFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Location of the bash history file.";
      };

      historyFileSize = mkOption {
        type = types.int;
        default = 100000;
        description = "Number of history lines to keep on file.";
      };

      historyControl = mkOption {
        type = types.listOf
          (types.enum [ "erasedups" "ignoredups" "ignorespace" "ignoreboth" ]);
        default = [ ];
        description = "Controlling how commands are saved on the history list.";
      };

      historyIgnore = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "ls" "cd" "exit" ];
        description =
          "List of commands that should not be saved to the history list.";
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
        example = [ "extglob" "-cdspell" ];
        description = ''
          Shell options to set. Prefix an option with
          "`-`" to unset.
        '';
      };

      sessionVariables = mkOption {
        default = { };
        type = types.attrs;
        example = { MAILCHECK = 30; };
        description = ''
          Environment variables that will be set for the Bash session.
        '';
      };

      shellAliases = mkOption {
        default = { };
        type = types.attrsOf types.str;
        example = literalExpression ''
          {
            ll = "ls -l";
            ".." = "cd ..";
          }
        '';
        description = ''
          An attribute set that maps aliases (the top level attribute names in
          this option) to command strings or directly to build outputs.
        '';
      };

      profileExtra = mkOption {
        default = "";
        type = types.lines;
        description = ''
          Extra commands that should be run when initializing a login
          shell.
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

      bashrcExtra = mkOption {
        default = "";
        type = types.lines;
        description = ''
          Extra commands that should be placed in {file}`~/.bashrc`.
          Note that these commands will be run even in non-interactive shells.
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

  config = let
    aliasesStr = concatStringsSep "\n"
      (mapAttrsToList (k: v: "alias ${k}=${escapeShellArg v}")
        cfg.shellAliases);

    shoptsStr = let switch = v: if hasPrefix "-" v then "-u" else "-s";
    in concatStringsSep "\n"
    (map (v: "shopt ${switch v} ${removePrefix "-" v}") cfg.shellOptions);

    sessionVarsStr = config.lib.shell.exportAll cfg.sessionVariables;

    historyControlStr = concatStringsSep "\n"
      (mapAttrsToList (n: v: "${n}=${v}") ({
        HISTFILESIZE = toString cfg.historyFileSize;
        HISTSIZE = toString cfg.historySize;
      } // optionalAttrs (cfg.historyFile != null) {
        HISTFILE = ''"${cfg.historyFile}"'';
      } // optionalAttrs (cfg.historyControl != [ ]) {
        HISTCONTROL = concatStringsSep ":" cfg.historyControl;
      } // optionalAttrs (cfg.historyIgnore != [ ]) {
        HISTIGNORE = escapeShellArg (concatStringsSep ":" cfg.historyIgnore);
      }));
  in mkIf cfg.enable {
    home.packages = [ pkgs.bashInteractive ];

    home.file.".bash_profile".source = writeBashScript "bash_profile" ''
      # include .profile if it exists
      [[ -f ~/.profile ]] && . ~/.profile

      # include .bashrc if it exists
      [[ -f ~/.bashrc ]] && . ~/.bashrc
    '';

    # If completion is enabled then make sure it is sourced very early. This
    # is to avoid problems if any other initialization code attempts to set up
    # completion.
    programs.bash.initExtra = mkIf cfg.enableCompletion (mkOrder 100 ''
      if [[ ! -v BASH_COMPLETION_VERSINFO ]]; then
        . "${pkgs.bash-completion}/etc/profile.d/bash_completion.sh"
      fi
    '');

    home.file.".profile".source = writeBashScript "profile" ''
      . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"

      ${sessionVarsStr}

      ${cfg.profileExtra}
    '';

    home.file.".bashrc".source = writeBashScript "bashrc" ''
      ${cfg.bashrcExtra}

      # Commands that should be applied only for interactive shells.
      [[ $- == *i* ]] || return

      ${historyControlStr}

      ${shoptsStr}

      ${aliasesStr}

      ${cfg.initExtra}
    '';

    home.file.".bash_logout" = mkIf (cfg.logoutExtra != "") {
      source = writeBashScript "bash_logout" cfg.logoutExtra;
    };
  };
}
