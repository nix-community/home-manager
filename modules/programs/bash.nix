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
  meta.maintainers = [ maintainers.rycee hm.maintainers.maximsmol ];

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
        type =
          types.listOf (types.enum [ "erasedups" "ignoredups" "ignorespace" ]);
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
          <quote><literal>-</literal></quote> to unset.
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
          Extra commands that should be placed in <filename>~/.bashrc</filename>.
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

      enableCompletion = mkEnableOption "Bash completion" // {
        default = true;
      };
    };
  };

  config = (let
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
        HISTIGNORE = concatStringsSep ":" cfg.historyIgnore;
      }));
  in mkIf cfg.enable {
    home.packages = with pkgs;
      [ ] ++ optional cfg.enableCompletion bash-completion;

    home.file.".bash_profile".source = writeBashScript "bash_profile" ''
      # include .profile if it exists
      [[ -f ~/.profile ]] && . ~/.profile

      # include .bashrc if it exists
      [[ -f ~/.bashrc ]] && . ~/.bashrc
    '';

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

      ${optionalString cfg.enableCompletion ''
        # Check whether we're running a version of Bash that has support for
        # programmable completion. If we do, enable all modules installed in
        # the system (and user profile).
        if shopt -q progcomp &>/dev/null; then
          . "${pkgs.bash-completion}/etc/profile.d/bash_completion.sh"
          nullglobStatus=$(shopt -p nullglob)
          shopt -s nullglob
          for p in $NIX_PROFILES; do
            for m in "$p/etc/bash_completion.d/"* "$p/share/bash-completion/completions/"*; do
              . $m
            done
          done
          eval "$nullglobStatus"
          unset nullglobStatus p m
        fi
      ''}

      ${cfg.initExtra}
    '';

    home.file.".bash_logout" = mkIf (cfg.logoutExtra != "") {
      source = writeBashScript "bash_logout" cfg.logoutExtra;
    };
  });
}
