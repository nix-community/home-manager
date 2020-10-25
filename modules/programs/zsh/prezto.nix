{ config, pkgs, lib, ... }:

with lib;

let

  cfg = config.programs.zsh.prezto;

  relToDotDir = file:
    (optionalString (config.programs.zsh.dotDir != null)
      (config.programs.zsh.dotDir + "/")) + file;

  preztoModule = types.submodule {
    options = {
      enable = mkEnableOption "prezto";

      caseSensitive = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description =
          "Set case-sensitivity for completion, history lookup, etc.";
      };

      color = mkOption {
        type = types.nullOr types.bool;
        default = true;
        example = false;
        description = "Color output (auto set to 'no' on dumb terminals)";
      };

      pmoduleDirs = mkOption {
        type = types.listOf types.path;
        default = [ ];
        example = [ "$HOME/.zprezto-contrib" ];
        description = "Add additional directories to load prezto modules from";
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Additional configuration to add to <filename>.zpreztorc</filename>.
        '';
      };

      extraModules = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "attr" "stat" ];
        description = "Set the Zsh modules to load (man zshmodules).";
      };

      extraFunctions = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "zargs" "zmv" ];
        description = "Set the Zsh functions to load (man zshcontrib).";
      };

      pmodules = mkOption {
        type = types.listOf types.str;
        default = [
          "environment"
          "terminal"
          "editor"
          "history"
          "directory"
          "spectrum"
          "utility"
          "completion"
          "prompt"
        ];
        description =
          "Set the Prezto modules to load (browse modules). The order matters.";
      };

      autosuggestions.color = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "fg=blue";
        description = "Set the query found color.";
      };

      completions.ignoredHosts = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "0.0.0.0" "127.0.0.1" ];
        description =
          "Set the entries to ignore in static */etc/hosts* for host completion.";
      };

      editor = {
        keymap = mkOption {
          type = types.nullOr (types.enum [ "emacs" "vi" ]);
          default = "emacs";
          example = "vi";
          description = "Set the key mapping style to 'emacs' or 'vi'.";
        };

        dotExpansion = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = true;
          description = "Auto convert .... to ../..";
        };

        promptContext = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = true;
          description = "Allow the zsh prompt context to be shown.";
        };
      };

      git.submoduleIgnore = mkOption {
        type = types.nullOr (types.enum [ "dirty" "untracked" "all" "none" ]);
        default = null;
        example = "all";
        description =
          "Ignore submodules when they are 'dirty', 'untracked', 'all', or 'none'.";
      };

      gnuUtility.prefix = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "g";
        description = "Set the command prefix on non-GNU systems.";
      };

      historySubstring = {
        foundColor = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "fg=blue";
          description = "Set the query found color.";
        };

        notFoundColor = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "fg=red";
          description = "Set the query not found color.";
        };

        globbingFlags = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Set the search globbing flags.";
        };
      };

      macOS.dashKeyword = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "manpages";
        description =
          "Set the keyword used by `mand` to open man pages in Dash.app";
      };

      prompt = {
        theme = mkOption {
          type = types.nullOr types.str;
          default = "sorin";
          example = "pure";
          description = ''
            Set the prompt theme to load. Setting it to 'random'
                      loads a random theme. Auto set to 'off' on dumb terminals.'';
        };

        pwdLength = mkOption {
          type = types.nullOr (types.enum [ "short" "long" "full" ]);
          default = null;
          example = "short";
          description = ''
            Set the working directory prompt display length. By
                      default, it is set to 'short'. Set it to 'long' (without '~' expansion) for
                      longer or 'full' (with '~' expansion) for even longer prompt display.'';
        };

        showReturnVal = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = true;
          description = ''
            Set the prompt to display the return code along with an
                      indicator for non-zero return codes. This is not supported by all prompts.'';
        };
      };

      python = {
        virtualenvAutoSwitch = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = true;
          description = "Auto switch to Python virtualenv on directory change.";
        };

        virtualenvInitialize = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = true;
          description =
            "Automatically initialize virtualenvwrapper if pre-requisites are met.";
        };
      };

      ruby.chrubyAutoSwitch = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = "Auto switch the Ruby version on directory change.";
      };

      screen = {
        autoStartLocal = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = true;
          description =
            "Auto start a session when Zsh is launched in a local terminal.";
        };

        autoStartRemote = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = true;
          description =
            "Auto start a session when Zsh is launched in a SSH connection.";
        };
      };

      ssh.identities = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "id_rsa" "id_rsa2" "id_github" ];
        description = "Set the SSH identities to load into the agent.";
      };

      syntaxHighlighting = {
        highlighters = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [ "main" "brackets" "pattern" "line" "cursor" "root" ];
          description = ''
            Set syntax highlighters. By default, only the main
                      highlighter is enabled.'';
        };

        styles = mkOption {
          type = types.attrsOf types.str;
          default = { };
          example = {
            builtin = "bg=blue";
            command = "bg=blue";
            function = "bg=blue";
          };
          description = "Set syntax highlighting styles.";
        };

        pattern = mkOption {
          type = types.attrsOf types.str;
          default = { };
          example = { "rm*-rf*" = "fg=white,bold,bg=red"; };
          description = "Set syntax pattern styles.";
        };
      };

      terminal = {
        autoTitle = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = true;
          description = "Auto set the tab and window titles.";
        };

        windowTitleFormat = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "%n@%m: %s";
          description = "Set the window title format.";
        };

        tabTitleFormat = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "%m: %s";
          description = "Set the tab title format.";
        };

        multiplexerTitleFormat = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "%s";
          description = "Set the multiplexer title format.";
        };
      };

      tmux = {
        autoStartLocal = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = true;
          description =
            "Auto start a session when Zsh is launched in a local terminal.";
        };

        autoStartRemote = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = true;
          description =
            "Auto start a session when Zsh is launched in a SSH connection.";
        };

        itermIntegration = mkOption {
          type = types.nullOr types.bool;
          default = null;
          example = true;
          description = "Integrate with iTerm2.";
        };

        defaultSessionName = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "YOUR DEFAULT SESSION NAME";
          description = "Set the default session name.";
        };
      };

      utility.safeOps = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = ''
          Enabled safe options. This aliases cp, ln, mv and rm so
                  that they prompt before deleting or overwriting files. Set to 'no' to disable
                  this safer behavior.'';
      };
    };
  };

in {
  options = {
    programs.zsh = {
      prezto = mkOption {
        type = preztoModule;
        default = { };
        description = "Options to configure prezto.";
      };
    };
  };
  config = mkIf cfg.enable (mkMerge [{
    home.file."${relToDotDir ".zprofile"}".text =
      builtins.readFile "${pkgs.zsh-prezto}/runcoms/zprofile";
    home.file."${relToDotDir ".zlogin"}".text =
      builtins.readFile "${pkgs.zsh-prezto}/runcoms/zlogin";
    home.file."${relToDotDir ".zlogout"}".text =
      builtins.readFile "${pkgs.zsh-prezto}/runcoms/zlogout";
    home.packages = with pkgs; [ zsh-prezto ];

    home.file."${relToDotDir ".zshenv"}".text =
      (builtins.readFile "${pkgs.zsh-prezto}/runcoms/zshenv");
    home.file."${relToDotDir ".zpreztorc"}".text = ''
      # Generated by Nix
      ${optionalString (cfg.caseSensitive != null) ''
        zstyle ':prezto:*:*' case-sensitive '${
          if cfg.caseSensitive then "yes" else "no"
        }'
      ''}
      ${optionalString (cfg.color != null) ''
        zstyle ':prezto:*:*' color '${if cfg.color then "yes" else "no"}'
      ''}
      ${optionalString (cfg.pmoduleDirs != [ ]) ''
        zstyle ':prezto:load' pmodule-dirs ${
          builtins.concatStringsSep " " cfg.pmoduleDirs
        }
      ''}
      ${optionalString (cfg.extraModules != [ ]) ''
        zstyle ':prezto:load' zmodule ${
          strings.concatMapStringsSep " " strings.escapeShellArg
          cfg.extraModules
        }
      ''}
      ${optionalString (cfg.extraFunctions != [ ]) ''
        zstyle ':prezto:load' zfunction ${
          strings.concatMapStringsSep " " strings.escapeShellArg
          cfg.extraFunctions
        }
      ''}
      ${optionalString (cfg.pmodules != [ ]) ''
        zstyle ':prezto:load' pmodule \
          ${
            strings.concatMapStringsSep " \\\n  " strings.escapeShellArg
            cfg.pmodules
          }
      ''}
      ${optionalString (cfg.autosuggestions.color != null) ''
        zstyle ':prezto:module:autosuggestions:color' found '${cfg.autosuggestions.color}'
      ''}
      ${optionalString (cfg.completions.ignoredHosts != [ ]) ''
        zstyle ':prezto:module:completion:*:hosts' etc-host-ignores \
          ${
            strings.concatMapStringsSep " " strings.escapeShellArg
            cfg.completions.ignoredHosts
          }
      ''}
      ${optionalString (cfg.editor.keymap != null) ''
        zstyle ':prezto:module:editor' key-bindings '${cfg.editor.keymap}'
      ''}
      ${optionalString (cfg.editor.dotExpansion != null) ''
        zstyle ':prezto:module:editor' dot-expansion '${
          if cfg.editor.dotExpansion then "yes" else "no"
        }'
      ''}
      ${optionalString (cfg.editor.promptContext != null) ''
        zstyle ':prezto:module:editor' ps-context '${
          if cfg.editor.promptContext then "yes" else "no"
        }'
      ''}
      ${optionalString (cfg.git.submoduleIgnore != null) ''
        zstyle ':prezto:module:git:status:ignore' submodules '${cfg.git.submoduleIgnore}'
      ''}
      ${optionalString (cfg.gnuUtility.prefix != null) ''
        zstyle ':prezto:module:gnu-utility' prefix '${cfg.gnuUtility.prefix}'
      ''}
      ${optionalString (cfg.historySubstring.foundColor != null) ''
        zstyle ':prezto:module:history-substring-search:color' found '${cfg.historySubstring.foundColor}'
      ''}
      ${optionalString (cfg.historySubstring.notFoundColor != null) ''
        zstyle ':prezto:module:history-substring-search:color' not-found '${cfg.historySubstring.notFoundColor}'
      ''}
      ${optionalString (cfg.historySubstring.globbingFlags != null) ''
        zstyle ':prezto:module:history-substring-search:color' globbing-flags '${cfg.historySubstring.globbingFlags}'
      ''}
      ${optionalString (cfg.macOS.dashKeyword != null) ''
        zstyle ':prezto:module:osx:man' dash-keyword '${cfg.macOS.dashKeyword}'
      ''}
      ${optionalString (cfg.prompt.theme != null) ''
        zstyle ':prezto:module:prompt' theme '${cfg.prompt.theme}'
      ''}
      ${optionalString (cfg.prompt.pwdLength != null) ''
        zstyle ':prezto:module:prompt' pwd-length '${cfg.prompt.pwdLength}'
      ''}
      ${optionalString (cfg.prompt.showReturnVal != null) ''
        zstyle ':prezto:module:prompt' show-return-val '${cfg.prompt.showReturnVal}'
      ''}
      ${optionalString (cfg.python.virtualenvAutoSwitch != null) ''
        zstyle ':prezto:module:python:virtualenv' auto-switch '${
          if cfg.python.virtualenvAutoSwitch then "yes" else "no"
        }'
      ''}
      ${optionalString (cfg.python.virtualenvInitialize != null) ''
        zstyle ':prezto:module:python:virtualenv' initialize '${
          if cfg.python.virtualenvInitialize then "yes" else "no"
        }'
      ''}
      ${optionalString (cfg.ruby.chrubyAutoSwitch != null) ''
        zstyle ':prezto:module:ruby:chruby' auto-switch '${
          if cfg.ruby.chrubyAutoSwitch then "yes" else "no"
        }'
      ''}
      ${optionalString (cfg.screen.autoStartLocal != null) ''
        zstyle ':prezto:module:screen:auto-start' local '${
          if cfg.screen.autoStartLocal then "yes" else "no"
        }'
      ''}
      ${optionalString (cfg.screen.autoStartRemote != null) ''
        zstyle ':prezto:module:screen:auto-start' remote '${
          if cfg.screen.autoStartRemote then "yes" else "no"
        }'
      ''}
      ${optionalString (cfg.ssh.identities != [ ]) ''
        zstyle ':prezto:module:ssh:load' identities \
          ${
            strings.concatMapStringsSep " " strings.escapeShellArg
            cfg.ssh.identities
          }
      ''}
      ${optionalString (cfg.syntaxHighlighting.highlighters != [ ]) ''
        zstyle ':prezto:module:syntax-highlighting' highlighters \
          ${
            strings.concatMapStringsSep " \\\n  " strings.escapeShellArg
            cfg.syntaxHighlighting.highlighters
          }
      ''}
      ${optionalString (cfg.syntaxHighlighting.styles != { }) ''
        zstyle ':prezto:module:syntax-highlighting' styles \
          ${
            builtins.concatStringsSep " \\\n" (attrsets.mapAttrsToList
              (k: v: strings.escapeShellArg k + " " + strings.escapeShellArg v)
              cfg.syntaxHighlighting.styles)
          }
      ''}
      ${optionalString (cfg.syntaxHighlighting.pattern != { }) ''
        zstyle ':prezto:module:syntax-highlighting' pattern \
          ${
            builtins.concatStringsSep " \\\n" (attrsets.mapAttrsToList
              (k: v: strings.escapeShellArg k + " " + strings.escapeShellArg v)
              cfg.syntaxHighlighting.pattern)
          }
      ''}
      ${optionalString (cfg.terminal.autoTitle != null) ''
        zstyle ':prezto:module:terminal' auto-title '${
          if cfg.terminal.autoTitle then "yes" else "no"
        }'
      ''}
      ${optionalString (cfg.terminal.windowTitleFormat != null) ''
        zstyle ':prezto:module:terminal:window-title' format '${cfg.terminal.windowTitleFormat}'
      ''}
      ${optionalString (cfg.terminal.tabTitleFormat != null) ''
        zstyle ':prezto:module:terminal:tab-title' format '${cfg.terminal.tabTitleFormat}'
      ''}
      ${optionalString (cfg.terminal.multiplexerTitleFormat != null) ''
        zstyle ':prezto:module:terminal:multiplexer-title' format '${cfg.terminal.multiplexerTitleFormat}'
      ''}
      ${optionalString (cfg.tmux.autoStartLocal != null) ''
        zstyle ':prezto:module:tmux:auto-start' local '${
          if cfg.tmux.autoStartLocal then "yes" else "no"
        }'
      ''}
      ${optionalString (cfg.tmux.autoStartRemote != null) ''
        zstyle ':prezto:module:tmux:auto-start' remote '${
          if cfg.tmux.autoStartRemote then "yes" else "no"
        }'
      ''}
      ${optionalString (cfg.tmux.itermIntegration != null) ''
        zstyle ':prezto:module:tmux:iterm' integrate '${
          if cfg.tmux.itermIntegration then "yes" else "no"
        }'
      ''}
      ${optionalString (cfg.tmux.defaultSessionName != null) ''
        zstyle ':prezto:module:tmux:session' name '${cfg.tmux.defaultSessionName}'
      ''}
      ${optionalString (cfg.utility.safeOps != null) ''
        zstyle ':prezto:module:utility' safe-ops '${
          if cfg.utility.safeOps then "yes" else "no"
        }'
      ''}
      ${cfg.extraConfig}
    '';
  }]);
}
