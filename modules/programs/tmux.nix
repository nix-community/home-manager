{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.tmux;

  pluginName = p: if types.package.check p then p.pname else p.plugin.pname;

  pluginModule = types.submodule {
    options = {
      plugin = mkOption {
        type = types.package;
        description = "Path of the configuration file to include.";
      };

      extraConfig = mkOption {
        type = types.lines;
        description = "Additional configuration for the associated plugin.";
        default = "";
      };
    };
  };

  defaultKeyMode = "emacs";
  defaultResize = 5;
  defaultShortcut = "b";
  defaultTerminal = "screen";
  defaultShell = null;

  boolToStr = value: if value then "on" else "off";

  tmuxConf = ''
    ${optionalString cfg.sensibleOnTop ''
      # ============================================= #
      # Start with defaults from the Sensible plugin  #
      # --------------------------------------------- #
      run-shell ${pkgs.tmuxPlugins.sensible.rtp}
      # ============================================= #
    ''}
    set  -g default-terminal "${cfg.terminal}"
    set  -g base-index      ${toString cfg.baseIndex}
    setw -g pane-base-index ${toString cfg.baseIndex}
    ${optionalString (cfg.shell != null) ''
      # We need to set default-shell before calling new-session
      set  -g default-shell "${cfg.shell}"
    ''}
    ${optionalString cfg.newSession "new-session"}

    ${optionalString cfg.reverseSplit ''
      bind v split-window -h
      bind s split-window -v
    ''}

    set -g status-keys ${cfg.keyMode}
    set -g mode-keys   ${cfg.keyMode}

    ${optionalString
    (cfg.keyMode == "vi" && cfg.customPaneNavigationAndResize) ''
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      bind -r H resize-pane -L ${toString cfg.resizeAmount}
      bind -r J resize-pane -D ${toString cfg.resizeAmount}
      bind -r K resize-pane -U ${toString cfg.resizeAmount}
      bind -r L resize-pane -R ${toString cfg.resizeAmount}
    ''}

    ${if cfg.prefix != null then ''
      # rebind main key: ${cfg.prefix}
      unbind C-${defaultShortcut}
      set -g prefix ${cfg.prefix}
      bind ${cfg.prefix} send-prefix
    '' else
      optionalString (cfg.shortcut != defaultShortcut) ''
        # rebind main key: C-${cfg.shortcut}
        unbind C-${defaultShortcut}
        set -g prefix C-${cfg.shortcut}
        bind ${cfg.shortcut} send-prefix
        bind C-${cfg.shortcut} last-window
      ''}

    ${optionalString cfg.disableConfirmationPrompt ''
      bind-key & kill-window
      bind-key x kill-pane
    ''}

    setw -g aggressive-resize ${boolToStr cfg.aggressiveResize}
    setw -g clock-mode-style  ${if cfg.clock24 then "24" else "12"}
    set  -s escape-time       ${toString cfg.escapeTime}
    set  -g history-limit     ${toString cfg.historyLimit}
  '';

  configPlugins = {
    assertions = [
      (let
        hasBadPluginName = p: !(hasPrefix "tmuxplugin" (pluginName p));
        badPlugins = filter hasBadPluginName cfg.plugins;
      in {
        assertion = badPlugins == [ ];
        message = ''Invalid tmux plugin (not prefixed with "tmuxplugins"): ''
          + concatMapStringsSep ", " pluginName badPlugins;
      })
    ];

    xdg.configFile."tmux/tmux.conf".text = ''
      # ============================================= #
      # Load plugins with Home Manager                #
      # --------------------------------------------- #

      ${(concatMapStringsSep "\n\n" (p: ''
        # ${pluginName p}
        # ---------------------
        ${p.extraConfig or ""}
        run-shell ${if types.package.check p then p.rtp else p.plugin.rtp}
      '') cfg.plugins)}
      # ============================================= #
    '';
  };

in {
  options = {
    programs.tmux = {
      aggressiveResize = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Resize the window to the size of the smallest session for
          which it is the current window.
        '';
      };

      baseIndex = mkOption {
        default = 0;
        example = 1;
        type = types.ints.unsigned;
        description = "Base index for windows and panes.";
      };

      clock24 = mkOption {
        default = false;
        type = types.bool;
        description = "Use 24 hour clock.";
      };

      customPaneNavigationAndResize = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Override the hjkl and HJKL bindings for pane navigation and
          resizing in VI mode.
        '';
      };

      disableConfirmationPrompt = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Disable confirmation prompt before killing a pane or window
        '';
      };

      enable = mkEnableOption "tmux";

      escapeTime = mkOption {
        default = 500;
        example = 0;
        type = types.ints.unsigned;
        description = ''
          Time in milliseconds for which tmux waits after an escape is
          input.
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Additional configuration to add to
          <filename>tmux.conf</filename>.
        '';
      };

      historyLimit = mkOption {
        default = 2000;
        example = 5000;
        type = types.ints.positive;
        description = "Maximum number of lines held in window history.";
      };

      keyMode = mkOption {
        default = defaultKeyMode;
        example = "vi";
        type = types.enum [ "emacs" "vi" ];
        description = "VI or Emacs style shortcuts.";
      };

      newSession = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Automatically spawn a session if trying to attach and none
          are running.
        '';
      };

      package = mkOption {
        type = types.package;
        default = pkgs.tmux;
        defaultText = literalExpression "pkgs.tmux";
        example = literalExpression "pkgs.tmux";
        description = "The tmux package to install";
      };

      reverseSplit = mkOption {
        default = false;
        type = types.bool;
        description = "Reverse the window split shortcuts.";
      };

      resizeAmount = mkOption {
        default = defaultResize;
        example = 10;
        type = types.ints.positive;
        description = "Number of lines/columns when resizing.";
      };

      sensibleOnTop = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Run the sensible plugin at the top of the configuration. It
          is possible to override the sensible settings using the
          <option>programs.tmux.extraConfig</option> option.
        '';
      };

      prefix = mkOption {
        default = null;
        example = "C-a";
        type = types.nullOr types.str;
        description = ''
          Set the prefix key. Overrules the "shortcut" option when set.
        '';
      };

      shortcut = mkOption {
        default = defaultShortcut;
        example = "a";
        type = types.str;
        description = ''
          CTRL following by this key is used as the main shortcut.
        '';
      };

      terminal = mkOption {
        default = defaultTerminal;
        example = "screen-256color";
        type = types.str;
        description = "Set the $TERM variable.";
      };

      shell = mkOption {
        default = defaultShell;
        example = "\${pkgs.zsh}/bin/zsh";
        type = with types; nullOr str;
        description = "Set the default-shell tmux variable.";
      };

      secureSocket = mkOption {
        default = pkgs.stdenv.isLinux;
        type = types.bool;
        description = ''
          Store tmux socket under <filename>/run</filename>, which is more
          secure than <filename>/tmp</filename>, but as a downside it doesn't
          survive user logout.
        '';
      };

      tmuxp.enable = mkEnableOption "tmuxp";

      tmuxinator.enable = mkEnableOption "tmuxinator";

      plugins = mkOption {
        type = with types;
          listOf (either package pluginModule) // {
            description = "list of plugin packages or submodules";
          };
        description = ''
          List of tmux plugins to be included at the end of your tmux
          configuration. The sensible plugin, however, is defaulted to
          run at the top of your configuration.
        '';
        default = [ ];
        example = literalExpression ''
          with pkgs; [
            tmuxPlugins.cpu
            {
              plugin = tmuxPlugins.resurrect;
              extraConfig = "set -g @resurrect-strategy-nvim 'session'";
            }
            {
              plugin = tmuxPlugins.continuum;
              extraConfig = '''
                set -g @continuum-restore 'on'
                set -g @continuum-save-interval '60' # minutes
              ''';
            }
          ]
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge ([
    {
      home.packages = [ cfg.package ]
        ++ optional cfg.tmuxinator.enable pkgs.tmuxinator
        ++ optional cfg.tmuxp.enable pkgs.tmuxp;
    }

    { xdg.configFile."tmux/tmux.conf".text = mkBefore tmuxConf; }
    { xdg.configFile."tmux/tmux.conf".text = mkAfter cfg.extraConfig; }

    (mkIf cfg.secureSocket {
      home.sessionVariables = {
        TMUX_TMPDIR = ''''${XDG_RUNTIME_DIR:-"/run/user/\$(id -u)"}'';
      };
    })

    (mkIf (cfg.plugins != [ ]) configPlugins)
  ]));
}
