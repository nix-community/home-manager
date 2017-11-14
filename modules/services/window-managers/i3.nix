{ config, lib, pkgs, ... }:

with lib;
with import ../../lib/dag.nix { inherit lib; };

let

  cfg = config.xsession.windowManager.i3;

  startupModule = types.submodule {
    options = {
      command = mkOption {
        type = types.string;
        description = "Command that will be executed on startup.";
      };

      always = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to run command on each i3 restart.";
      };

      notification = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to enable startup-notification support for the command.
          See --no-startup-id option description in the i3 user guide.
        '';
      };

      workspace = mkOption {
        type = types.nullOr types.string;
        default = null;
        description = "Launch application on a particular workspace.";
      };
    };
  };

  colorSetModule = types.submodule {
    options = {
      border = mkOption {
        type = types.string;
        visible = false;
      };

      childBorder = mkOption {
        type = types.string;
        visible = false;
      };

      background = mkOption {
        type = types.string;
        visible = false;
      };

      text = mkOption {
        type = types.string;
        visible = false;
      };

      indicator = mkOption {
        type = types.string;
        visible = false;
      };
    };
  };

  barModule = types.submodule {
    options = {
      mode = mkOption {
        type = types.enum [ "dock" "hide" "invisible" ];
        default = "dock";
        description = "Bar visibility mode.";
      };

      hiddenState = mkOption {
        type = types.enum [ "hide" "show" ];
        default = "hide";
        description = "The default bar mode when 'bar.mode' == 'hide'.";
      };

      position = mkOption {
        type = types.enum [ "top" "bottom" ];
        default = "bottom";
        description = "The edge of the screen i3bar should show up.";
      };

      workspaceButtons = mkOption {
        type = types.bool;
        default = true;
        description = "Whether workspace buttons should be shown or not.";
      };

      statusCommand = mkOption {
        type = types.string;
        default = "${pkgs.i3status}/bin/i3status";
        description = "Command that will be used to get status lines.";
      };

    };
  };

  criteriaModule = types.attrs;

  configModule = types.submodule {
    options = {
      fonts = mkOption {
        type = types.listOf types.string;
        default = ["monospace 8"];
        description = ''
          Font list used for window titles. Only FreeType fonts are supported.
          The order here is improtant (e.g. icons font should go before the one used for text).
        '';
        example = [ "FontAwesome 10" "Terminus 10" ];
      };

      window = mkOption {
        type = types.submodule {
          options = {
            titlebar = mkOption {
              type = types.bool;
              default = cfg.package != pkgs.i3-gaps;
              defaultText = "xsession.windowManager.i3.package != nixpkgs.i3-gaps (titlebar should be disabled for i3-gaps)";
              description = "Whether to show window titlebars.";
            };

            border = mkOption {
              type = types.int;
              default = 2;
              description = "Window border width.";
            };
          };
        };
        default = {};
        description = "Window titlebar and border settings.";
      };

      floating = mkOption {
        type = types.submodule {
          options = {
            titlebar = mkOption {
              type = types.bool;
              default = cfg.package != pkgs.i3-gaps;
              defaultText = "xsession.windowManager.i3.package != nixpkgs.i3-gaps (titlebar should be disabled for i3-gaps)";
              description = "Whether to show floating window titlebars.";
            };

            border = mkOption {
              type = types.int;
              default = 2;
              description = "Floating windows border width.";
            };

            modifier = mkOption {
              type = types.enum [ "Shift" "Control" "Mod1" "Mod2" "Mod3" "Mod4" "Mod5" ];
              default = "Mod1";
              description = "Modifier key that can be used to drag floating windows.";
              example = "Mod4";
            };

            criteria = mkOption {
              type = types.listOf criteriaModule;
              default = [];
              description = "List of criteria for windows that should be opened in a floating mode.";
              example = [ "title='Steam - Update News'" "class='Pavucontrol'" ];
            };
          };
        };
        default = {};
        description = "Floating window settings.";
      };

      focus = mkOption {
        type = types.submodule {
          options = {
            newWindow = mkOption {
              type =types.enum [ "smart" "urgent" "focus" "none" ];
              default = "smart";
              description = ''
                This option modifies focus behavior on new window activation.

                See <link xlink:href="https://i3wm.org/docs/userguide.html#focus_on_window_activation"/>
              '';
              example = "none";
            };

            followMouse = mkOption {
              type = types.bool;
              default = true;
              description = "Whether focus should follow the mouse.";
            };

            forceWrapping = mkOption {
              type = types.bool;
              default = false;
              description = ''
                Whether to force focus wrapping in tabbed or stacked container.

                See <link xlink:href="https://i3wm.org/docs/userguide.html#_focus_wrapping"/>
              '';
            };
          };
        };
        default = {};
        description = "Focus related settings.";
      };

      assigns = mkOption {
        type = types.attrsOf (types.listOf criteriaModule);
        default = {};
        description = ''
          An attribute set that assignes applications to workspaces based
          on criteria.
        '';
        example = literalExample ''
          {
            "1: web" = [{ class = "^Firefox$"; }];
            "0: extra" = [{ class = "^Firefox$"; window_role = "About"; }];
          }
        '';
      };

      keybindings = mkOption {
        type = types.attrs;
        default = {
          "Mod1+Return" = "exec i3-sensible-terminal";
          "Mod1+Shift+q" = "kill";
          "Mod1+d" = "exec ${pkgs.dmenu}/bin/dmenu_run";

          "Mod1+Left" = "focus left";
          "Mod1+Down" = "focus down";
          "Mod1+Up" = "focus up";
          "Mod1+Right" = "focus right";

          "Mod1+h" = "split h";
          "Mod1+v" = "split v";
          "Mod1+f" = "fullscreen toggle";

          "Mod1+s" = "layout stacking";
          "Mod1+w" = "layout tabbed";
          "Mod1+e" = "layout toggle split";

          "Mod1+Shift+space" = "floating toggle";

          "Mod1+1" = "workspace 1";
          "Mod1+2" = "workspace 2";
          "Mod1+3" = "workspace 3";
          "Mod1+4" = "workspace 4";
          "Mod1+5" = "workspace 5";
          "Mod1+6" = "workspace 6";
          "Mod1+7" = "workspace 7";
          "Mod1+8" = "workspace 8";
          "Mod1+9" = "workspace 9";

          "Mod1+Shift+1" = "move container to workspace 1";
          "Mod1+Shift+2" = "move container to workspace 2";
          "Mod1+Shift+3" = "move container to workspace 3";
          "Mod1+Shift+4" = "move container to workspace 4";
          "Mod1+Shift+5" = "move container to workspace 5";
          "Mod1+Shift+6" = "move container to workspace 6";
          "Mod1+Shift+7" = "move container to workspace 7";
          "Mod1+Shift+8" = "move container to workspace 8";
          "Mod1+Shift+9" = "move container to workspace 9";

          "Mod1+Shift+c" = "reload";
          "Mod1+Shift+r" = "restart";
          "Mod1+Shift+e" = "exec i3-nagbar -t warning -m 'Do you want to exit i3?' -b 'Yes' 'i3-msg exit'";

          "Mod1+r" = "mode resize";
        };
        defaultText = "Default i3 keybindings.";
        description = ''
          An attribute set that assignes keypress to an action.
          Only basic keybinding is supported (bindsym keycomb action),
          for more advanced setup use 'i3.extraConfig'.
        '';
        example = literalExample ''
          {
            "Mod1+Return" = "exec i3-sensible-terminal";
            "Mod1+Shift+q" = "kill";
            "Mod1+d" = "exec ${pkgs.dmenu}/bin/dmenu_run";
          }
        '';
      };

      colors = mkOption {
        type = types.submodule {
          options = {
            background = mkOption {
              type = types.string;
              default = "#ffffff";
              description = ''
                Background color of the window. Only applications which do not cover
                the whole area expose the color.
              '';
            };

            focused = mkOption {
              type = colorSetModule;
              default = {
                border = "#4c7899"; background = "#285577"; text = "#ffffff";
                indicator = "#2e9ef4"; childBorder = "#285577";
              };
              description = "A window which currently has the focus.";
            };

            focusedInactive = mkOption {
              type = colorSetModule;
              default = {
                border = "#333333"; background = "#5f676a"; text = "#ffffff";
                indicator = "#484e50"; childBorder = "#5f676a";
              };
              description = ''
                A window which is the focused one of its container,
                but it does not have the focus at the moment.
              '';
            };

            unfocused = mkOption {
              type = colorSetModule;
              default = {
                border = "#333333"; background = "#222222"; text = "#888888";
                indicator = "#292d2e"; childBorder = "#222222";
              };
              description = "A window which is not focused.";
            };

            urgent = mkOption {
              type = colorSetModule;
              default = {
                border = "#2f343a"; background = "#900000"; text = "#ffffff";
                indicator = "#900000"; childBorder = "#900000";
              };
              description = "A window which has its urgency hint activated.";
            };

            placeholder = mkOption {
              type = colorSetModule;
              default = {
                border = "#000000"; background = "#0c0c0c"; text = "#ffffff";
                indicator = "#000000"; childBorder = "#0c0c0c";
              };
              description = ''
                Background and text color are used to draw placeholder window
                contents (when restoring layouts). Border and indicator are ignored.
              '';
            };
          };
        };
        default = {};
        description = ''
          Color settings. All color classes can be specified using submodules
          with 'border', 'background', 'text', 'indicator' and 'childBorder' fields
          and RGB color hex-codes as values. See default values for the reference.
          Note that 'i3.config.colors.background' parameter takes a single RGB value.

          See <link xlink:href="https://i3wm.org/docs/userguide.html#_changing_colors"/>.
        '';
      };

      modes = mkOption {
        type = types.attrsOf types.attrs;
        default = {
          resize = {
            "Left" = "resize shrink width 10 px or 10 ppt";
            "Down" = "resize grow height 10 px or 10 ppt";
            "Up" = "resize shrink height 10 px or 10 ppt";
            "Right" = "resize grow width 10 px or 10 ppt";
            "Escape" = "mode default";
          };
        };
        description = ''
          An attribute set that defines binding modes and keybindings
          inside them

          Only basic keybinding is supported (bindsym keycomb action),
          for more advanced setup use 'i3.extraConfig'.
        '';
      };

      bars = mkOption {
        type = types.listOf barModule;
        default = [{}];
        description = ''
          i3 bars settings blocks. Set to empty list to remove bars completely.
        '';
      };

      startup = mkOption {
        type = types.listOf startupModule;
        default = [];
        description = ''
          Commands that should be executed at startup.

          See <link xlink:href="https://i3wm.org/docs/userguide.html#_automatically_starting_applications_on_i3_startup"/>.
        '';
        example = literalExample ''
          [
            { command = "systemctl --user restart polybar"; always = true; notification = false; }
            { command = "dropbox start"; notification = false; }
            { command = "firefox"; workspace = "1: web"; }
          ];
        '';
      };

      gaps = mkOption {
        type = types.nullOr (types.submodule {
          options = {
            inner = mkOption {
              type = types.nullOr types.int;
              default = null;
              description = "Inner gaps value.";
              example = 12;
            };

            outer = mkOption {
              type = types.nullOr types.int;
              default = null;
              description = "Outer gaps value.";
              example = 5;
            };

            smartGaps = mkOption {
              type = types.bool;
              default = false;
              description = ''
                This option controls whether to disable all gaps (outer and inner)
                on workspace with a single container.
              '';
              example = true;
            };

            smartBorders = mkOption {
              type = types.enum [ "on" "off" "no_gaps" ];
              default = null;
              description = ''
                This option controls whether to disable container borders on
                workspace with a single container.
              '';
              example = true;
            };
          };
        });
        default = null;
        description = ''
          i3gaps related settings.
          Note that i3-gaps package should be set for this options to take effect.
        '';
      };
    };
  };

  keybindingsStr = keybindings: concatStringsSep "\n" (
    mapAttrsToList (keycomb: action: "bindsym ${keycomb} ${action}") keybindings
  );

  colorSetStr = c: concatStringsSep " " [ c.border c.background c.text c.indicator c.childBorder ];

  criteriaStr = criteria: "[${concatStringsSep " " (mapAttrsToList (k: v: ''${k}="${v}"'') criteria)}]";

  modeStr = name: keybindings: ''
    mode "${name}" {
    ${keybindingsStr keybindings}
    }
  '';

  assignStr = workspace: criteria: concatStringsSep "\n" (
    map (c: "assign ${criteriaStr c} ${workspace}") criteria
  );

  barStr = { mode, hiddenState, position, workspaceButtons, statusCommand, ... }: ''
    bar {
      mode ${mode}
      hidden_state ${hiddenState}
      position ${position}
      status_command ${statusCommand}
      workspace_buttons ${if workspaceButtons then "yes" else "no"}
    }
  '';

  gapsStr = with cfg.config.gaps; ''
    ${optionalString (inner != null) "gaps inner ${toString inner}"}
    ${optionalString (outer != null) "gaps outer ${toString outer}"}
    ${optionalString smartGaps "smart_gaps on"}
    ${optionalString (smartBorders != "off") "smart_borders ${smartBorders}"}
  '';

  floatingCriteriaStr = criteria: "for_window ${criteriaStr criteria} floating enable";

  startupEntryStr = { command, always, notification, workspace, ... }: ''
    ${if always then "exec_always" else "exec"} ${
      if (notification && workspace == null) then "" else "--no-startup-id"
    } ${
      if (workspace == null) then
        command
      else
        "i3-msg 'workspace ${workspace}; exec ${command}'"
    }
  '';

  configFile = pkgs.writeText "i3.conf" ((if cfg.config != null then with cfg.config; ''
    font pango:${concatStringsSep ", " fonts}
    floating_modifier ${floating.modifier}
    new_window ${if window.titlebar then "normal" else "pixel"} ${toString window.border}
    new_float ${if floating.titlebar then "normal" else "pixel"} ${toString floating.border}
    force_focus_wrapping ${if focus.forceWrapping then "yes" else "no"}
    focus_follows_mouse ${if focus.followMouse then "yes" else "no"}
    focus_on_window_activation ${focus.newWindow}

    client.focused ${colorSetStr colors.focused}
    client.focused_inactive ${colorSetStr colors.focusedInactive}
    client.unfocused ${colorSetStr colors.unfocused}
    client.urgent ${colorSetStr colors.urgent}
    client.placeholder ${colorSetStr colors.placeholder}
    client.background ${colors.background}

    ${keybindingsStr keybindings}
    ${concatStringsSep "\n" (mapAttrsToList modeStr modes)}
    ${concatStringsSep "\n" (mapAttrsToList assignStr assigns)}
    ${concatStringsSep "\n" (map barStr bars)}
    ${optionalString (gaps != null) gapsStr}
    ${concatStringsSep "\n" (map floatingCriteriaStr floating.criteria)}
    ${concatStringsSep "\n" (map startupEntryStr startup)}
  '' else "") + "\n" + cfg.extraConfig);

in

{
  options = {
    xsession.windowManager.i3 = {
      enable = mkEnableOption "i3 window manager.";

      package = mkOption {
        type = types.package;
        default = pkgs.i3;
        defaultText = "pkgs.i3";
        example = "pkgs.i3-gaps";
        description = ''
          i3 package to use.
          If 'i3.config.gaps' settings are specified, 'pkgs.i3-gaps' will be set as a default package.
        '';
      };

      config = mkOption {
        type = types.nullOr configModule;
        default = {};
        description = "i3 configuration options.";
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Extra configuration lines to add to ~/.config/i3/config.";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [ cfg.package ];
      xsession.windowManager.command = "${cfg.package}/bin/i3";
      xdg.configFile."i3/config".source = configFile;

      home.activation.checkI3 = dagEntryBefore [ "linkGeneration" ] ''
        if ! cmp --quiet \
            "${configFile}" \
            "${config.xdg.configHome}/i3/config"; then
          i3Changed=1
        fi
      '';

      home.activation.reloadI3 = dagEntryAfter [ "linkGeneration" ] ''
        if [[ -v i3Changed && -v DISPLAY ]]; then
          echo "Reloading i3"
          ${cfg.package}/bin/i3-msg reload 1>/dev/null
        fi
      '';
    }

    (mkIf (cfg.config != null) {
      xsession.windowManager.i3.package = mkDefault (
        if (cfg.config.gaps != null) then pkgs.i3-gaps else pkgs.i3
      );
    })
  ]);
}
