{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.zsh;

  inherit (lib) literalExpression mkOption types;

  inherit (import ./lib.nix { inherit config lib; }) dotDirAbs mkShellVarPathStr;
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
              default = "${dotDirAbs}/.zsh_history";
              defaultText = "`\${config.programs.zsh.dotDir}/.zsh_history`";
              example = "`\${config.xdg.dataHome}/zsh/zsh_history`";
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
    warnings =
      lib.optionals (!lib.hasPrefix "/" cfg.history.path && !lib.hasInfix "$" cfg.history.path)
        [
          ''
            Using relative paths in programs.zsh.history.path is deprecated and will be removed in a future release.
            Consider using absolute paths or home-manager config options instead.
            You can replace relative paths or environment variables with options like:
            - config.home.homeDirectory (user's home directory)
            - config.xdg.configHome (XDG config directory)
            - config.xdg.dataHome (XDG data directory)
            - config.xdg.cacheHome (XDG cache directory)
            Current history.path: ${cfg.history.path}
          ''
        ];

    programs.zsh.initContent = lib.mkMerge [
      (lib.mkOrder 910 ''
        # History options should be set in .zshrc and after oh-my-zsh sourcing.
        # See https://github.com/nix-community/home-manager/issues/177.
        HISTSIZE="${toString cfg.history.size}"
        SAVEHIST="${toString cfg.history.save}"
        ${lib.optionalString (
          cfg.history.ignorePatterns != [ ]
        ) "HISTORY_IGNORE=${lib.escapeShellArg "(${lib.concatStringsSep "|" cfg.history.ignorePatterns})"}"}
        HISTFILE="${mkShellVarPathStr cfg.history.path}"
        mkdir -p "$(dirname "$HISTFILE")"

        setopt HIST_FCNTL_LOCK

        ${
          let
            historyOptions = {
              APPEND_HISTORY = cfg.history.append;
              HIST_IGNORE_DUPS = cfg.history.ignoreDups;
              HIST_IGNORE_ALL_DUPS = cfg.history.ignoreAllDups;
              HIST_SAVE_NO_DUPS = cfg.history.saveNoDups;
              HIST_FIND_NO_DUPS = cfg.history.findNoDups;
              HIST_IGNORE_SPACE = cfg.history.ignoreSpace;
              HIST_EXPIRE_DUPS_FIRST = cfg.history.expireDuplicatesFirst;
              SHARE_HISTORY = cfg.history.share;
              EXTENDED_HISTORY = cfg.history.extended;
            }
            // lib.optionalAttrs (cfg.autocd != null) {
              inherit (cfg) autocd;
            };

            enabledOpts = lib.filterAttrs (_: enabled: enabled) historyOptions;
            disabledOpts = lib.filterAttrs (_: enabled: !enabled) historyOptions;
          in
          lib.concatStringsSep "\n\n" (
            lib.filter (s: s != "") [
              (lib.optionalString (enabledOpts != { }) ''
                # Enabled history options
                ${lib.hm.zsh.define "enabled_opts" (lib.mapAttrsToList (name: _: name) enabledOpts)}
                for opt in "''${enabled_opts[@]}"; do
                  setopt "$opt"
                done
                unset opt enabled_opts'')
              (lib.optionalString (disabledOpts != { }) ''
                # Disabled history options
                ${lib.hm.zsh.define "disabled_opts" (lib.mapAttrsToList (name: _: name) disabledOpts)}
                for opt in "''${disabled_opts[@]}"; do
                  unsetopt "$opt"
                done
                unset opt disabled_opts'')
            ]
          )
        }
      '')

      (lib.mkIf (cfg.historySubstringSearch.enable or false) (
        lib.mkOrder 1250
          # Load zsh-history-substring-search after zsh-syntax-highlighting
          # https://github.com/zsh-users/zsh-history-substring-search#usage
          ''
            source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh

            ${
              let
                upKeys = lib.toList cfg.historySubstringSearch.searchUpKey;
                downKeys = lib.toList cfg.historySubstringSearch.searchDownKey;
              in
              ''
                # Bind search up keys
                ${lib.hm.zsh.define "search_up_keys" upKeys}
                 for key in "''${search_up_keys[@]}"; do
                   bindkey "$key" history-substring-search-up
                 done
                 unset key search_up_keys

                # Bind search down keys
                ${lib.hm.zsh.define "search_down_keys" downKeys}
                 for key in "''${search_down_keys[@]}"; do
                   bindkey "$key" history-substring-search-down
                 done
                 unset key search_down_keys
              ''
            }
          ''
      ))
    ];
  };
}
