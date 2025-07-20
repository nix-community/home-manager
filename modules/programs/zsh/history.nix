{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.zsh;

  inherit (lib) literalExpression mkOption types;
  inherit (config.home) stateVersion;

  relToDotDir = file: (lib.optionalString (cfg.dotDir != null) (cfg.dotDir + "/")) + file;
in
{
  options =
    let
      historyModule = types.submodule (
        { config, ... }:
        {
          options = {
            append = mkOption {
              type = types.bool;
              default = false;
              description = ''
                If set, zsh sessions will append their history list to the history
                file, rather than replace it. Thus, multiple parallel zsh sessions
                will all have the new entries from their history lists added to the
                history file, in the order that they exit.

                This file will still be periodically re-written to trim it when the
                number of lines grows 20% beyond the value specified by
                `programs.zsh.history.save`.
              '';
            };

            size = mkOption {
              type = types.int;
              default = 10000;
              description = "Number of history lines to keep.";
            };

            save = mkOption {
              type = types.int;
              defaultText = 10000;
              default = config.size;
              description = "Number of history lines to save.";
            };

            path = mkOption {
              type = types.str;
              default =
                if lib.versionAtLeast stateVersion "20.03" then
                  "$HOME/.zsh_history"
                else
                  relToDotDir ".zsh_history";
              defaultText = literalExpression ''
                "$HOME/.zsh_history" if state version ≥ 20.03,
                "$ZDOTDIR/.zsh_history" otherwise
              '';
              example = literalExpression ''"''${config.xdg.dataHome}/zsh/zsh_history"'';
              description = "History file location";
            };

            ignorePatterns = mkOption {
              type = types.listOf types.str;
              default = [ ];
              example = literalExpression ''[ "rm *" "pkill *" ]'';
              description = ''
                Do not enter command lines into the history list
                if they match any one of the given shell patterns.
              '';
            };

            ignoreDups = mkOption {
              type = types.bool;
              default = true;
              description = ''
                Do not enter command lines into the history list
                if they are duplicates of the previous event.
              '';
            };

            ignoreAllDups = mkOption {
              type = types.bool;
              default = false;
              description = ''
                If a new command line being added to the history list
                duplicates an older one, the older command is removed
                from the list (even if it is not the previous event).
              '';
            };

            saveNoDups = mkOption {
              type = types.bool;
              default = false;
              description = ''
                Do not write duplicate entries into the history file.
              '';
            };

            findNoDups = mkOption {
              type = types.bool;
              default = false;
              description = ''
                Do not display a line previously found in the history
                file.
              '';
            };

            ignoreSpace = mkOption {
              type = types.bool;
              default = true;
              description = ''
                Do not enter command lines into the history list
                if the first character is a space.
              '';
            };

            expireDuplicatesFirst = mkOption {
              type = types.bool;
              default = false;
              description = "Expire duplicates first.";
            };

            extended = mkOption {
              type = types.bool;
              default = false;
              description = "Save timestamp into the history file.";
            };

            share = mkOption {
              type = types.bool;
              default = true;
              description = "Share command history between zsh sessions.";
            };
          };
        }
      );

      historySubstringSearchModule = types.submodule {
        options = {
          enable = lib.mkEnableOption "history substring search";
          searchUpKey = mkOption {
            type = with types; either (listOf str) str;
            default = [ "^[[A" ];
            description = ''
              The key codes to be used when searching up.
              The default of `^[[A` may correspond to the UP key -- if not, try
              `$terminfo[kcuu1]`.
            '';
          };
          searchDownKey = mkOption {
            type = with types; either (listOf str) str;
            default = [ "^[[B" ];
            description = ''
              The key codes to be used when searching down.
              The default of `^[[B` may correspond to the DOWN key -- if not, try
              `$terminfo[kcud1]`.
            '';
          };
        };
      };
    in
    {
      programs.zsh = {
        history = mkOption {
          type = historyModule;
          default = { };
          description = "Options related to commands history configuration.";
        };

        historySubstringSearch = mkOption {
          type = historySubstringSearchModule;
          default = { };
          description = "Options related to zsh-history-substring-search.";
        };
      };
    };

  config = {
    programs.zsh.initContent = lib.mkMerge [
      (lib.mkOrder 910 ''
        # History options should be set in .zshrc and after oh-my-zsh sourcing.
        # See https://github.com/nix-community/home-manager/issues/177.
        HISTSIZE="${toString cfg.history.size}"
        SAVEHIST="${toString cfg.history.save}"
        ${lib.optionalString (
          cfg.history.ignorePatterns != [ ]
        ) "HISTORY_IGNORE=${lib.escapeShellArg "(${lib.concatStringsSep "|" cfg.history.ignorePatterns})"}"}
        ${
          if lib.versionAtLeast stateVersion "20.03" then
            ''HISTFILE="${cfg.history.path}"''
          else
            ''HISTFILE="$HOME/${cfg.history.path}"''
        }
        mkdir -p "$(dirname "$HISTFILE")"

        setopt HIST_FCNTL_LOCK
        ${if cfg.history.append then "setopt" else "unsetopt"} APPEND_HISTORY
        ${if cfg.history.ignoreDups then "setopt" else "unsetopt"} HIST_IGNORE_DUPS
        ${if cfg.history.ignoreAllDups then "setopt" else "unsetopt"} HIST_IGNORE_ALL_DUPS
        ${if cfg.history.saveNoDups then "setopt" else "unsetopt"} HIST_SAVE_NO_DUPS
        ${if cfg.history.findNoDups then "setopt" else "unsetopt"} HIST_FIND_NO_DUPS
        ${if cfg.history.ignoreSpace then "setopt" else "unsetopt"} HIST_IGNORE_SPACE
        ${if cfg.history.expireDuplicatesFirst then "setopt" else "unsetopt"} HIST_EXPIRE_DUPS_FIRST
        ${if cfg.history.share then "setopt" else "unsetopt"} SHARE_HISTORY
        ${if cfg.history.extended then "setopt" else "unsetopt"} EXTENDED_HISTORY
        ${if cfg.autocd != null then "${if cfg.autocd then "setopt" else "unsetopt"} autocd" else ""}
      '')

      (lib.mkIf (cfg.historySubstringSearch.enable or false) (
        lib.mkOrder 1250
          # Load zsh-history-substring-search after zsh-syntax-highlighting
          # https://github.com/zsh-users/zsh-history-substring-search#usage
          ''
            source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh
            ${lib.concatMapStringsSep "\n" (upKey: ''bindkey "${upKey}" history-substring-search-up'') (
              lib.toList cfg.historySubstringSearch.searchUpKey
            )}
            ${lib.concatMapStringsSep "\n" (downKey: ''bindkey "${downKey}" history-substring-search-down'') (
              lib.toList cfg.historySubstringSearch.searchDownKey
            )}
          ''
      ))
    ];
  };
}
