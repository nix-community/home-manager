{
  config,
  lib,
  pkgs,
  options,
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
  bindkeyCommands = {
    emacs = "bindkey -e";
    viins = "bindkey -v";
    vicmd = "bindkey -a";
  };

  zshLib = import ./lib.nix { inherit config lib; };
  inherit (zshLib) homeDir dotDirAbs dotDirRel;
in
{
  meta.maintainers = [ lib.maintainers.khaneliman ];

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
            defaultText = ''[ "main" ]'';
            example = [ "brackets" ];
            description = ''
              Highlighters to enable
              See the list of highlighters: <https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/docs/highlighters.md>

              Note: The "main" highlighter is always included automatically.
              If you'd like to exclude it, please configure with a higher priority using `mkForce`.
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

      fastSyntaxHighlightingModule = types.submodule {
        options = {
          enable = mkEnableOption "zsh fast syntax highlighting";

          package = lib.mkPackageOption pkgs "zsh-fast-syntax-highlighting" { };

          theme = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "clean";
            description = ''
              If non-null, Home Manager will run {command}`fast-theme -q`
              with this value to select the theme. `fast-theme` persists the
              selected theme in fast-syntax-highlighting's work directory, so
              setting this option back to `null` stops Home Manager from
              invoking {command}`fast-theme` but does not reset an already
              persisted theme. Run {command}`fast-theme -r` manually to clear
              upstream state.

              See [upstream's documentation](https://github.com/zdharma-continuum/fast-syntax-highlighting/blob/master/THEME_GUIDE.md)
            '';
          };

          settings = mkOption {
            type = types.attrsOf types.str;
            default = { };
            example = {
              use_brackets = "0";
              "chroma-," = "→chroma/-precommand.ch";
              "chroma-comma" = "→chroma/-precommand.ch";
            };
            description = ''
              Custom values to add to `FAST_HIGHLIGHT`, like custom chroma
              configuration (see [upstream's documentation](https://github.com/zdharma-continuum/fast-syntax-highlighting/blob/master/CHROMA_GUIDE.adoc)
              and its [built-in chromas](https://github.com/zdharma-continuum/fast-syntax-highlighting/tree/master/%E2%86%92chroma)).
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
          default =
            if config.xdg.enable && lib.versionAtLeast config.home.stateVersion "26.05" then
              "${config.xdg.configHome}/zsh"
            else
              homeDir;
          defaultText = lib.literalExpression ''
            if config.xdg.enable && lib.versionAtLeast config.home.stateVersion "26.05" then
              "''${config.xdg.configHome}/zsh"
            else
              config.home.homeDirectory
          '';
          example = literalExpression ''"''${config.xdg.configHome}/zsh"'';
          description = ''
            Directory where the zsh configuration and more should be located,
            relative to the users home directory. The default is the home
            directory.
          '';
          type = types.nullOr types.str;
        };

        shellAliases = mkOption {
          default = { };
          example = {
            ll = "ls -l";
            ".." = "cd ..";
          };
          description = ''
            An attribute set that maps aliases (the top level attribute names in
            this option) to command strings or directly to build outputs.
          '';
          type = types.attrsOf types.str;
        };

        shellGlobalAliases = mkOption {
          default = { };
          example = {
            UUID = "$(uuidgen | tr -d \\n)";
            G = "| grep";
          };
          description = ''
            Similar to [](#opt-programs.zsh.shellAliases),
            but are substituted anywhere on a line.
          '';
          type = types.attrsOf types.str;
        };

        shellSuffixAliases = mkOption {
          default = { };
          example = {
            ps = "gv --";
          };
          description = ''
            Suffix Aliases used when a file with a matching suffix is called
            without any other commands.
          '';
        };

        dirHashes = mkOption {
          default = { };
          example = literalExpression ''
            {
              docs  = "$\{config.home.homeDirectory}/Documents";
              vids  = "$\{config.home.homeDirectory}/Videos";
              dl    = "$\{config.home.homeDirectory}/Downloads";
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

        fastSyntaxHighlighting = mkOption {
          type = fastSyntaxHighlightingModule;
          default = { };
          description = "Options related to zsh-fast-syntax-highlighting.";
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
          type =
            with types;
            lazyAttrsOf (
              nullOr (oneOf [
                str
                path
                int
                float
                bool
              ])
            );
          example = {
            MAILCHECK = 30;
          };
          description = ''
            Environment variables that will be set for zsh session.

            Setting a value to `null` will skip setting the variable at all, which
            may be useful when overriding.
          '';
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

        functions = mkOption {
          type = types.attrsOf types.lines;
          default = { };
          example = {
            pargs = "print $0: $*";
          };
          description = ''
            Functions added to .zshrc
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

        zstyle = mkOption {
          type = types.attrsOf (types.attrsOf types.anything);
          default = { };
          example = {
            auto-description = "'+%d'";
            file-sort = "name";
            use-cache = true;
            ignore-parents = [
              "parent"
              "pwd"
            ];
          };
          description = ''
            Configure zstyle options. See {manpage}`zshmodules(1)`.
            These are used to configure the completion System See {manpage}`zshcompsys(1).
          '';
        };

        bindkey = mkOption {
          type = types.attrsOf types.str;
          default = { };
          description = ''
            Keybinds set in Zsh via bindkey. The name is the keybind and value
            is the command.
          '';
          example = {
            "^A" = "beginning-of-line";
          };
        };

        zleFunctions = mkOption {
          type = types.attrsOf types.lines;
          default = { };
          description = ''
            Functions that are added to the Zsh environment and are added to the
            zsh command line editor via `zle -N`. The key is the name
            and the value is the body of the function to be added
          '';
          example = {
            mkcd = ''
              mkdir --parents "$1" && cd "$1"
            '';
          };
        };

        siteFunctions = mkOption {
          type = types.attrsOf types.lines;
          default = { };
          description = ''
            Functions that are added to the Zsh environment and are subject to
            {command}`autoload`ing. The key is the name and the value is the body of
            the function to be autoloaded.

            They are also already marked for autoloading through `autoload -Uz`.
          '';
          example = {
            mkcd = ''
              mkdir --parents "$1" && cd "$1"
            '';
          };
        };
      };
    };

  config =
    let
      envVarsStr = config.lib.zsh.exportAll cfg.sessionVariables { indent = "  "; };
      localVarsStr = config.lib.zsh.defineAll cfg.localVariables;
      sessionVarsStr = lib.removeSuffix "\n" ''
        # Environment variables
        . "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh"

        # Only source this once
        if [[ -z "''${__HM_ZSH_SESS_VARS_SOURCED-}" ]]; then
          export __HM_ZSH_SESS_VARS_SOURCED=1
          ${envVarsStr}
        fi
      '';
      indentNonEmptyLines =
        str:
        concatStringsSep "\n" (
          map (line: if line == "" then "" else "  ${line}") (lib.splitString "\n" str)
        );

      aliasesStr = concatStringsSep "\n" (
        lib.mapAttrsToList (
          k: v: "alias -- ${lib.escapeShellArg k}=${lib.escapeShellArg v}"
        ) cfg.shellAliases
      );

      # Keep double quotes so existing configs using shell variables like
      # $HOME still expand, while escaping chars special inside them.
      dirHashesStr = concatStringsSep "\n" (
        lib.mapAttrsToList (
          k: v: ''hash -d ${lib.escapeShellArg k}="${lib.escape [ "\\" "\"" "`" ] v}"''
        ) cfg.dirHashes
      );
      cdpathStr = concatStringsSep " " (map (v: ''"${lib.escape [ "\\" "\"" "`" ] v}"'') cfg.cdpath);
    in
    mkIf cfg.enable (
      lib.mkMerge [
        {
          assertions = [
            {
              assertion = !lib.hasInfix "$" cfg.dotDir;
              message = ''
                programs.zsh.dotDir cannot contain shell variables as it is used for file creation at build time.
                Current dotDir: ${cfg.dotDir}
                Consider using an absolute path or home-manager config options instead.
                You can replace shell variables with options like:
                - config.home.homeDirectory (user's home directory)
                - config.xdg.configHome (XDG config directory)
                - config.xdg.dataHome (XDG data directory)
                - config.xdg.cacheHome (XDG cache directory)
              '';
            }
            {
              assertion =
                lib.count (x: x) [
                  cfg.syntaxHighlighting.enable
                  cfg.fastSyntaxHighlighting.enable
                ] <= 1;
              message = ''
                Only one Zsh syntax highlighter can be enabled at a time.
              '';
            }
          ];

          warnings =
            lib.optionals
              (cfg.dotDir != homeDir && !lib.hasPrefix "/" cfg.dotDir && !lib.hasInfix "$" cfg.dotDir)
              [
                ''
                  Using relative paths in programs.zsh.dotDir is deprecated and will be removed in a future release.
                  Current dotDir: ${cfg.dotDir}
                  Consider using absolute paths or home-manager config options instead.
                  You can replace relative paths or environment variables with options like:
                  - config.home.homeDirectory (user's home directory)
                  - config.xdg.configHome (XDG config directory)
                  - config.xdg.dataHome (XDG data directory)
                  - config.xdg.cacheHome (XDG cache directory)
                ''
              ]
            ++
              lib.optionals
                (
                  config.xdg.enable
                  && !lib.versionAtLeast config.home.stateVersion "26.05"
                  && options.programs.zsh.dotDir.highestPrio >= 1500
                )
                [
                  ''
                    The default value of `programs.zsh.dotDir` will change in future versions.
                    You are currently using the legacy default (home directory) because `home.stateVersion` is less than "26.05".
                    To silence this warning and lock in the current behavior, set:
                      programs.zsh.dotDir = config.home.homeDirectory;
                    To adopt the new behavior (XDG config directory), set:
                      programs.zsh.dotDir = "''${config.xdg.configHome}/zsh";
                  ''
                ];
        }

        (mkIf (cfg.envExtra != "") {
          home.file."${dotDirRel}/.zshenv".text = cfg.envExtra;
        })

        (mkIf (cfg.loginExtra != "") {
          home.file."${dotDirRel}/.zlogin".text = cfg.loginExtra;
        })

        (mkIf (cfg.logoutExtra != "") {
          home.file."${dotDirRel}/.zlogout".text = cfg.logoutExtra;
        })

        (mkIf (dotDirAbs != homeDir) {
          home.file."${dotDirRel}/.zshenv".text = ''
            ${config.lib.zsh.export "ZDOTDIR" dotDirAbs}
          '';

          # When dotDir is set, only use ~/.zshenv to source ZDOTDIR/.zshenv,
          # This is so that if ZDOTDIR happens to be
          # already set correctly (by e.g. spawning a zsh inside a zsh), all env
          # vars still get exported
          home.file.".zshenv".text = ''
            source ${lib.escapeShellArg "${dotDirAbs}/.zshenv"}
          '';
        })

        (lib.mkIf (cfg.siteFunctions != { }) {
          assertions = lib.mapAttrsToList (funcName: _text: {
            assertion = !(lib.hasPrefix "/" funcName);
            message =
              "programs.zsh.siteFunctions: function name '${funcName}' cannot start with a '/'. "
              + "either rename it, or don't rely on autoloading for that function (e.g. by defining it inside your '.zshrc')";
          }) cfg.siteFunctions;
          home.packages = lib.mapAttrsToList (
            name: pkgs.writeTextDir "share/zsh/site-functions/${name}"
          ) cfg.siteFunctions;
          programs.zsh.initContent = lib.escapeShellArgs (
            [
              "autoload"
              "-Uz"
              "--"
            ]
            ++ (lib.attrNames cfg.siteFunctions)
          );
        })

        (lib.mkIf (cfg.zleFunctions != { }) { programs.zsh.functions = cfg.zleFunctions; })

        {
          home.file."${dotDirRel}/.zshenv".text = ''
            if [[ ! -o login ]]; then
            ${indentNonEmptyLines sessionVarsStr}
            fi
          '';

          home.file."${dotDirRel}/.zprofile".text = ''
            ${sessionVarsStr}
          ''
          + optionalString (cfg.profileExtra != "") ''

            ${cfg.profileExtra}
          '';
        }

        {
          lib.zsh = zshLib;

          home.packages = [
            cfg.package
          ]
          ++ lib.optional cfg.enableCompletion (lib.lowPrio pkgs.nix-zsh-completions);

          # NOTE: Always include "main" highlighter with normal priority.
          # Option default priority will cause `main` to get dropped by customization.
          programs.zsh.syntaxHighlighting.highlighters = lib.mkIf cfg.syntaxHighlighting.enable [ "main" ];

          programs.zsh.initContent = lib.mkMerge [
            (mkOrder 510 "typeset -U path cdpath fpath manpath")

            (lib.mkIf (cfg.cdpath != [ ]) (
              mkOrder 510 ''
                cdpath+=(${cdpathStr})
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

            (lib.mkIf (cfg.functions != { }) (
              mkOrder 550 (
                concatStringsSep "\n" (
                  lib.mapAttrsToList (name: def: ''
                    function ${name} {
                      ${def}
                    }
                  '') cfg.functions
                )
              )
            ))

            (lib.mkIf (cfg.zleFunctions != { }) (
              mkOrder 560 (
                concatStringsSep "\n" (lib.mapAttrsToList (name: _def: "zle -N ${name}") cfg.zleFunctions)
              )
            ))

            # NOTE: Oh-My-Zsh/Prezto calls compinit during initialization,
            # calling it twice causes slight start up slowdown
            # as all $fpath entries will be traversed again.
            (lib.mkIf (cfg.enableCompletion && !cfg.oh-my-zsh.enable && !cfg.prezto.enable) (
              mkOrder 570 cfg.completionInit
            ))

            (lib.mkIf (cfg.bindkey != { }) (
              mkOrder 580 (
                concatStringsSep "\n" (lib.mapAttrsToList (name: def: "bindkey '${name}' ${def}") cfg.bindkey)
              )
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
                # Set shell options
                ${lib.hm.zsh.define "set_opts" cfg.setOptions}
                for opt in "''${set_opts[@]}"; do
                  setopt "$opt"
                done
                unset opt set_opts
              ''
            ))

            (lib.mkIf (aliasesStr != "" || cfg.shellGlobalAliases != { } || cfg.shellSuffixAliases != { }) (
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
                + (optionalString (cfg.shellSuffixAliases != { }) (
                  optionalString (cfg.shellGlobalAliases != { } || cfg.shellAliases != { }) "\n"
                  + (concatStringsSep "\n" (
                    lib.mapAttrsToList (
                      k: v: "alias -s -- ${lib.escapeShellArg k}=${lib.escapeShellArg v}"
                    ) cfg.shellSuffixAliases
                  ))
                ))
              )
            ))

            (lib.mkIf (cfg.zstyle != { }) (
              mkOrder 1120 (
                concatStringsSep "\n" (
                  lib.flatten (
                    lib.mapAttrsToList (
                      pattern: set:
                      map (opts: "zstyle '${pattern}' ${opts}") (
                        lib.mapAttrsToList (name: val: "${name} ${(toString val)}") set
                      )
                    ) cfg.zstyle
                  )
                )
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
                  ZSH_HIGHLIGHT_HIGHLIGHTERS=(${lib.concatStringsSep " " (map lib.escapeShellArg cfg.syntaxHighlighting.highlighters)})
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

            (lib.mkIf cfg.fastSyntaxHighlighting.enable (
              mkOrder 1200
                # Load zsh-fast-syntax-highlighting after all custom widgets have been created
                ''
                  source ${cfg.fastSyntaxHighlighting.package}/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
                  ${lib.optionalString (cfg.fastSyntaxHighlighting.theme != null) ''
                    fast-theme -q ${cfg.fastSyntaxHighlighting.theme}
                  ''}
                  ${lib.concatStringsSep "\n" (
                    lib.mapAttrsToList (
                      name: value: "FAST_HIGHLIGHT+=(${lib.escapeShellArg name} ${lib.escapeShellArg value})"
                    ) cfg.fastSyntaxHighlighting.settings
                  )}
                ''
            ))
          ];

          home.file."${dotDirRel}/.zshrc".text = cfg.initContent;
        }
      ]
    );
}
