{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    literalExpression
    mkEnableOption
    mkIf
    mkOption
    mkOrder
    optionalString
    types
    ;

  cfg = config.programs.zsh;

  relToDotDir = file: (optionalString (cfg.dotDir != null) (cfg.dotDir + "/")) + file;

  bindkeyCommands = {
    emacs = "bindkey -e";
    viins = "bindkey -v";
    vicmd = "bindkey -a";
  };
in
{
  imports = [
    ./plugins
    ./deprecated.nix
    ./history.nix
  ];

  options =
    let
      syntaxHighlightingModule = types.submodule {
        options = {
          enable = mkEnableOption "zsh syntax highlighting";

          package = lib.mkPackageOption pkgs "zsh-syntax-highlighting" { };

          highlighters = mkOption {
            type = types.listOf types.str;
            default = [ ];
            example = [ "brackets" ];
            description = ''
              Highlighters to enable
              See the list of highlighters: <https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters.md>
            '';
          };

          patterns = mkOption {
            type = types.attrsOf types.str;
            default = { };
            example = {
              "rm -rf *" = "fg=white,bold,bg=red";
            };
            description = ''
              Custom syntax highlighting for user-defined patterns.
              Reference: <https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters/pattern.md>
            '';
          };

          styles = mkOption {
            type = types.attrsOf types.str;
            default = { };
            example = {
              comment = "fg=black,bold";
            };
            description = ''
              Custom styles for syntax highlighting.
              See each highlighter style option: <https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters/main.md>
            '';
          };
        };
      };
    in
    {
      programs.zsh = {
        enable = mkEnableOption "Z shell (Zsh)";

        package = lib.mkPackageOption pkgs "zsh" { };

        autocd = mkOption {
          default = null;
          description = ''
            Automatically enter into a directory if typed directly into shell.
          '';
          type = types.nullOr types.bool;
        };

        cdpath = mkOption {
          default = [ ];
          description = ''
            List of paths to autocomplete calls to {command}`cd`.
          '';
          type = types.listOf types.str;
        };

        dotDir = mkOption {
          default = null;
          example = ".config/zsh";
          description = ''
            Directory where the zsh configuration and more should be located,
            relative to the users home directory. The default is the home
            directory.
          '';
          type = types.nullOr types.str;
        };

        shellAliases = mkOption {
          default = { };
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
          type = types.attrsOf types.str;
        };

        shellGlobalAliases = mkOption {
          default = { };
          example = literalExpression ''
            {
              UUID = "$(uuidgen | tr -d \\n)";
              G = "| grep";
            }
          '';
          description = ''
            Similar to [](#opt-programs.zsh.shellAliases),
            but are substituted anywhere on a line.
          '';
          type = types.attrsOf types.str;
        };

        dirHashes = mkOption {
          default = { };
          example = literalExpression ''
            {
              docs  = "$HOME/Documents";
              vids  = "$HOME/Videos";
              dl    = "$HOME/Downloads";
            }
          '';
          description = ''
            An attribute set that adds to named directory hash table.
          '';
          type = types.attrsOf types.str;
        };

        enableCompletion = mkOption {
          default = true;
          description = ''
            Enable zsh completion. Don't forget to add
            ```nix
              environment.pathsToLink = [ "/share/zsh" ];
            ```
            to your system configuration to get completion for system packages (e.g. systemd).
          '';
          type = types.bool;
        };

        completionInit = mkOption {
          default = "autoload -U compinit && compinit";
          description = "Initialization commands to run when completion is enabled.";
          type = types.lines;
        };

        syntaxHighlighting = mkOption {
          type = syntaxHighlightingModule;
          default = { };
          description = "Options related to zsh-syntax-highlighting.";
        };

        autosuggestion = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable zsh autosuggestions";
          };

          highlight = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "fg=#ff00ff,bg=cyan,bold,underline";
            description = ''
              Custom styles for autosuggestion highlighting. See
              {manpage}`zshzle(1)` for syntax.
            '';
          };

          strategy = mkOption {
            type = types.listOf (
              types.enum [
                "history"
                "completion"
                "match_prev_cmd"
              ]
            );
            default = [ "history" ];
            description = ''
              `ZSH_AUTOSUGGEST_STRATEGY` is an array that specifies how suggestions should be generated.
              The strategies in the array are tried successively until a suggestion is found.
              There are currently three built-in strategies to choose from:

              - `history`: Chooses the most recent match from history.
              - `completion`: Chooses a suggestion based on what tab-completion would suggest. (requires `zpty` module)
              - `match_prev_cmd`: Like `history`, but chooses the most recent match whose preceding history item matches
                  the most recently executed command. Note that this strategy won't work as expected with ZSH options that
                  don't preserve the history order such as `HIST_IGNORE_ALL_DUPS` or `HIST_EXPIRE_DUPS_FIRST`.

              Setting the option to an empty list `[]` will make ZSH_AUTOSUGGESTION_STRATEGY not be set automatically,
              allowing the variable to be declared in {option}`programs.zsh.localVariables` or {option}`programs.zsh.sessionVariables`
            '';
          };
        };

        defaultKeymap = mkOption {
          type = types.nullOr (types.enum (lib.attrNames bindkeyCommands));
          default = null;
          example = "emacs";
          description = "The default base keymap to use.";
        };

        sessionVariables = mkOption {
          default = { };
          type = types.attrs;
          example = {
            MAILCHECK = 30;
          };
          description = "Environment variables that will be set for zsh session.";
        };

        initContent = mkOption {
          default = "";
          type = types.lines;
          example = lib.literalExpression ''
            lib.mkOrder 1200 ''''
              echo "Hello zsh initContent!"
            '''';
          '';
          description = ''
            Content to be added to {file}`.zshrc`.

            To specify the order, use `lib.mkOrder`.

            Common order values:
            - 500 (mkBefore): Early initialization (replaces initExtraFirst)
            - 550: Before completion initialization (replaces initExtraBeforeCompInit)
            - 1000 (default): General configuration (replaces initExtra)
            - 1500 (mkAfter): Last to run configuration

            To specify both content in Early initialization and General configuration, use `lib.mkMerge`.

            e.g.

            initContent = let
                zshConfigEarlyInit = lib.mkOrder 500 "do something";
                zshConfig = lib.mkOrder 1000 "do something";
            in
                lib.mkMerge [ zshConfigEarlyInit zshConfig ];
          '';
        };

        envExtra = mkOption {
          default = "";
          type = types.lines;
          description = "Extra commands that should be added to {file}`.zshenv`.";
        };

        profileExtra = mkOption {
          default = "";
          type = types.lines;
          description = "Extra commands that should be added to {file}`.zprofile`.";
        };

        loginExtra = mkOption {
          default = "";
          type = types.lines;
          description = "Extra commands that should be added to {file}`.zlogin`.";
        };

        logoutExtra = mkOption {
          default = "";
          type = types.lines;
          description = "Extra commands that should be added to {file}`.zlogout`.";
        };

        localVariables = mkOption {
          type = types.attrs;
          default = { };
          example = {
            POWERLEVEL9K_LEFT_PROMPT_ELEMENTS = [
              "dir"
              "vcs"
            ];
          };
          description = ''
            Extra local variables defined at the top of {file}`.zshrc`.
          '';
        };

        setOptions = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [
            "EXTENDED_HISTORY"
            "RM_STAR_WAIT"
            "NO_BEEP"
          ];
          description = ''
            Configure zsh options. See
            {manpage}`zshoptions(1)`.

            To unset an option, prefix it with "NO_".
          '';
        };
      };
    };

  config =
    let
      envVarsStr = config.lib.zsh.exportAll cfg.sessionVariables;
      localVarsStr = config.lib.zsh.defineAll cfg.localVariables;

      aliasesStr = concatStringsSep "\n" (
        lib.mapAttrsToList (
          k: v: "alias -- ${lib.escapeShellArg k}=${lib.escapeShellArg v}"
        ) cfg.shellAliases
      );

      dirHashesStr = concatStringsSep "\n" (
        lib.mapAttrsToList (k: v: ''hash -d ${k}="${v}"'') cfg.dirHashes
      );

      zdotdir = "$HOME/" + lib.escapeShellArg cfg.dotDir;
    in
    mkIf cfg.enable (
      lib.mkMerge [
        (mkIf (cfg.envExtra != "") {
          home.file."${relToDotDir ".zshenv"}".text = cfg.envExtra;
        })

        (mkIf (cfg.profileExtra != "") {
          home.file."${relToDotDir ".zprofile"}".text = cfg.profileExtra;
        })

        (mkIf (cfg.loginExtra != "") {
          home.file."${relToDotDir ".zlogin"}".text = cfg.loginExtra;
        })

        (mkIf (cfg.logoutExtra != "") {
          home.file."${relToDotDir ".zlogout"}".text = cfg.logoutExtra;
        })

        (mkIf (cfg.dotDir != null) {
          home.file."${relToDotDir ".zshenv"}".text = ''
            export ZDOTDIR=${zdotdir}
          '';

          # When dotDir is set, only use ~/.zshenv to source ZDOTDIR/.zshenv,
          # This is so that if ZDOTDIR happens to be
          # already set correctly (by e.g. spawning a zsh inside a zsh), all env
          # vars still get exported
          home.file.".zshenv".text = ''
            source ${zdotdir}/.zshenv
          '';
        })

        {
          home.file."${relToDotDir ".zshenv"}".text = ''
            # Environment variables
            . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"

            # Only source this once
            if [[ -z "$__HM_ZSH_SESS_VARS_SOURCED" ]]; then
              export __HM_ZSH_SESS_VARS_SOURCED=1
              ${envVarsStr}
            fi
          '';
        }

        {
          home.packages = [ cfg.package ] ++ lib.optional cfg.enableCompletion pkgs.nix-zsh-completions;

          programs.zsh.initContent = lib.mkMerge [
            (mkOrder 510 "typeset -U path cdpath fpath manpath")

            (lib.mkIf (cfg.cdpath != [ ]) (
              mkOrder 510 ''
                cdpath+=(${concatStringsSep " " cfg.cdpath})
              ''
            ))

            (mkOrder 520 ''
              for profile in ''${(z)NIX_PROFILES}; do
                fpath+=($profile/share/zsh/site-functions $profile/share/zsh/$ZSH_VERSION/functions $profile/share/zsh/vendor-completions)
              done

              HELPDIR="${cfg.package}/share/zsh/$ZSH_VERSION/help"
            '')

            (lib.mkIf (cfg.defaultKeymap != null) (
              mkOrder 530 ''
                # Use ${cfg.defaultKeymap} keymap as the default.
                ${lib.getAttr cfg.defaultKeymap bindkeyCommands}
              ''
            ))

            (lib.mkIf (localVarsStr != "") (mkOrder 540 localVarsStr))

            # NOTE: Oh-My-Zsh/Prezto calls compinit during initialization,
            # calling it twice causes slight start up slowdown
            # as all $fpath entries will be traversed again.
            (lib.mkIf (cfg.enableCompletion && !cfg.oh-my-zsh.enable && !cfg.prezto.enable) (
              mkOrder 570 cfg.completionInit
            ))

            (lib.mkIf cfg.autosuggestion.enable (
              mkOrder 700 ''
                source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
                ${
                  optionalString (cfg.autosuggestion.strategy != [ ]) ''
                    ZSH_AUTOSUGGEST_STRATEGY=(${concatStringsSep " " cfg.autosuggestion.strategy})
                  ''
                }${
                  optionalString (cfg.autosuggestion.highlight != null) ''
                    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="${cfg.autosuggestion.highlight}"
                  ''
                }
              ''
            ))

            (lib.mkIf (cfg.setOptions != [ ]) (
              mkOrder 950 ''
                ${concatStringsSep "\n" (map (option: "setopt ${option}") cfg.setOptions)}
              ''
            ))

            (lib.mkIf (aliasesStr != "" || cfg.shellGlobalAliases != { }) (
              mkOrder 1100 (
                (optionalString (aliasesStr != "") aliasesStr)
                + (optionalString (cfg.shellGlobalAliases != { }) (
                  optionalString (cfg.shellAliases != { }) "\n"
                  + (concatStringsSep "\n" (
                    lib.mapAttrsToList (
                      k: v: "alias -g -- ${lib.escapeShellArg k}=${lib.escapeShellArg v}"
                    ) cfg.shellGlobalAliases
                  ))
                ))
              )
            ))

            (lib.mkIf (dirHashesStr != "") (
              mkOrder 1150 ''
                # Named Directory Hashes
                ${dirHashesStr}
              ''
            ))

            (lib.mkIf cfg.syntaxHighlighting.enable (
              mkOrder 1200
                # Load zsh-syntax-highlighting after all custom widgets have been created
                # https://github.com/zsh-users/zsh-syntax-highlighting#faq
                ''
                  source ${cfg.syntaxHighlighting.package}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
                  ZSH_HIGHLIGHT_HIGHLIGHTERS+=(${lib.concatStringsSep " " (map lib.escapeShellArg cfg.syntaxHighlighting.highlighters)})
                  ${lib.concatStringsSep "\n" (
                    lib.mapAttrsToList (
                      name: value: "ZSH_HIGHLIGHT_STYLES[${lib.escapeShellArg name}]=${lib.escapeShellArg value}"
                    ) cfg.syntaxHighlighting.styles
                  )}
                  ${lib.concatStringsSep "\n" (
                    lib.mapAttrsToList (
                      name: value: "ZSH_HIGHLIGHT_PATTERNS+=(${lib.escapeShellArg name} ${lib.escapeShellArg value})"
                    ) cfg.syntaxHighlighting.patterns
                  )}
                ''
            ))
          ];

          home.file."${relToDotDir ".zshrc"}".text = cfg.initContent;
        }
      ]
    );
}
