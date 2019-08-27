{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.xsession.windowManager.i3;

  commonOptions = {
    fonts = mkOption {
      type = types.listOf types.str;
      default = ["monospace 8"];
      description = ''
        Font list used for window titles. Only FreeType fonts are supported.
        The order here is improtant (e.g. icons font should go before the one used for text).
      '';
      example = [ "FontAwesome 10" "Terminus 10" ];
    };
  };

  startupModule = types.submodule {
    options = {
      command = mkOption {
        type = types.str;
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
          See <option>--no-startup-id</option> option description in the i3 user guide.
        '';
      };

      workspace = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Launch application on a particular workspace. DEPRECATED:
          Use <varname><link linkend="opt-xsession.windowManager.i3.config.assigns">xsession.windowManager.i3.config.assigns</link></varname>
          instead. See <link xlink:href="https://github.com/rycee/home-manager/issues/265"/>.
        '';
      };
    };
  };

  barColorSetModule = types.submodule {
    options = {
      border = mkOption {
        type = types.str;
        visible = false;
      };

      background = mkOption {
        type = types.str;
        visible = false;
      };

      text = mkOption {
        type = types.str;
        visible = false;
      };
    };
  };

  colorSetModule = types.submodule {
    options = {
      border = mkOption {
        type = types.str;
        visible = false;
      };

      childBorder = mkOption {
        type = types.str;
        visible = false;
      };

      background = mkOption {
        type = types.str;
        visible = false;
      };

      text = mkOption {
        type = types.str;
        visible = false;
      };

      indicator = mkOption {
        type = types.str;
        visible = false;
      };
    };
  };

  barModule = types.submodule {
    options = {
      inherit (commonOptions) fonts;

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Extra configuration lines for this bar.";
      };

      id = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Specifies the bar ID for the configured bar instance.
          If this option is missing, the ID is set to bar-x, where x corresponds
          to the position of the embedding bar block in the config file.
        '';
      };

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

      workspaceNumbers = mkOption {
        type = types.bool;
        default = true;
        description = "Whether workspace numbers should be displayed within the workspace buttons.";
      };

      command = mkOption {
        type = types.str;
        default = "${cfg.package}/bin/i3bar";
        defaultText = "i3bar";
        description = "Command that will be used to start a bar.";
        example = "\${pkgs.i3-gaps}/bin/i3bar -t";
      };

      statusCommand = mkOption {
        type = types.str;
        default = "${pkgs.i3status}/bin/i3status";
        description = "Command that will be used to get status lines.";
      };

      colors = mkOption {
        type = types.submodule {
          options = {
            background = mkOption {
              type = types.str;
              default = "#000000";
              description = "Background color of the bar.";
            };

            statusline = mkOption {
              type = types.str;
              default = "#ffffff";
              description = "Text color to be used for the statusline.";
            };

            separator = mkOption {
              type = types.str;
              default = "#666666";
              description = "Text color to be used for the separator.";
            };

            focusedWorkspace = mkOption {
              type = barColorSetModule;
              default = { border = "#4c7899"; background = "#285577"; text = "#ffffff"; };
              description = ''
                Border, background and text color for a workspace button when the workspace has focus.
              '';
            };

            activeWorkspace = mkOption {
              type = barColorSetModule;
              default = { border = "#333333"; background = "#5f676a"; text = "#ffffff"; };
              description = ''
                Border, background and text color for a workspace button when the workspace is active.
              '';
            };

            inactiveWorkspace = mkOption {
              type = barColorSetModule;
              default = { border = "#333333"; background = "#222222"; text = "#888888"; };
              description = ''
                Border, background and text color for a workspace button when the workspace does not
                have focus and is not active.
              '';
            };

            urgentWorkspace = mkOption {
              type = barColorSetModule;
              default = { border = "#2f343a"; background = "#900000"; text = "#ffffff"; };
              description = ''
                Border, background and text color for a workspace button when the workspace contains
                a window with the urgency hint set.
              '';
            };

            bindingMode = mkOption {
              type = barColorSetModule;
              default = { border = "#2f343a"; background = "#900000"; text = "#ffffff"; };
              description = "Border, background and text color for the binding mode indicator";
            };
          };
        };
        default = {};
        description = ''
          Bar color settings. All color classes can be specified using submodules
          with 'border', 'background', 'text', fields and RGB color hex-codes as values.
          See default values for the reference.
          Note that 'background', 'status', and 'separator' parameters take a single RGB value.

          See <link xlink:href="https://i3wm.org/docs/userguide.html#_colors"/>.
        '';
      };

      trayOutput = mkOption {
        type = types.str;
        default = "primary";
        description = "Where to output tray.";
      };
    };
  };

  windowCommandModule = types.submodule {
    options = {
      command = mkOption {
        type = types.str;
        description = "i3wm command to execute.";
        example = "border pixel 1";
      };

      criteria = mkOption {
        type = criteriaModule;
        description = "Criteria of the windows on which command should be executed.";
        example = { title = "x200: ~/work"; };
      };
    };
  };

  criteriaModule = types.attrsOf types.str;

  configModule = types.submodule {
    options = {
      inherit (commonOptions) fonts;

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

            hideEdgeBorders = mkOption {
              type = types.enum [ "none" "vertical" "horizontal" "both" "smart" ];
              default = "none";
              description = "Hide window borders adjacent to the screen edges.";
            };

            commands = mkOption {
              type = types.listOf windowCommandModule;
              default = [];
              description = ''
                List of commands that should be executed on specific windows.
                See <option>for_window</option> i3wm option documentation.
              '';
              example = [ { command = "border pixel 1"; criteria = { class = "XTerm"; }; } ];
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
              default = cfg.config.modifier;
              defaultText = "i3.config.modifier";
              description = "Modifier key that can be used to drag floating windows.";
              example = "Mod4";
            };

            criteria = mkOption {
              type = types.listOf criteriaModule;
              default = [];
              description = "List of criteria for windows that should be opened in a floating mode.";
              example = [ {"title" = "Steam - Update News";} {"class" = "Pavucontrol";} ];
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
              type = types.enum [ "smart" "urgent" "focus" "none" ];
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

            mouseWarping = mkOption {
              type = types.bool;
              default = true;
              description = ''
                Whether mouse cursor should be warped to the center of the window when switching focus
                to a window on a different output.
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
          An attribute set that assigns applications to workspaces based
          on criteria.
        '';
        example = literalExample ''
          {
            "1: web" = [{ class = "^Firefox$"; }];
            "0: extra" = [{ class = "^Firefox$"; window_role = "About"; }];
          }
        '';
      };

      modifier = mkOption {
        type = types.enum [ "Shift" "Control" "Mod1" "Mod2" "Mod3" "Mod4" "Mod5" ];
        default = "Mod1";
        description = "Modifier key that is used for all default keybindings.";
        example = "Mod4";
      };

      workspaceLayout = mkOption {
        type = types.enum [ "default" "stacked" "tabbed" ];
        default = "default";
        example = "tabbed";
        description = ''
          The mode in which new containers on workspace level will
          start.
        '';
      };

      keybindings = mkOption {
        type = types.attrsOf (types.nullOr types.str);
        default = mapAttrs (n: mkOptionDefault) {
          "${cfg.config.modifier}+Return" = "exec i3-sensible-terminal";
          "${cfg.config.modifier}+Shift+q" = "kill";
          "${cfg.config.modifier}+d" = "exec ${pkgs.dmenu}/bin/dmenu_run";

          "${cfg.config.modifier}+Left" = "focus left";
          "${cfg.config.modifier}+Down" = "focus down";
          "${cfg.config.modifier}+Up" = "focus up";
          "${cfg.config.modifier}+Right" = "focus right";

          "${cfg.config.modifier}+Shift+Left" = "move left";
          "${cfg.config.modifier}+Shift+Down" = "move down";
          "${cfg.config.modifier}+Shift+Up" = "move up";
          "${cfg.config.modifier}+Shift+Right" = "move right";

          "${cfg.config.modifier}+h" = "split h";
          "${cfg.config.modifier}+v" = "split v";
          "${cfg.config.modifier}+f" = "fullscreen toggle";

          "${cfg.config.modifier}+s" = "layout stacking";
          "${cfg.config.modifier}+w" = "layout tabbed";
          "${cfg.config.modifier}+e" = "layout toggle split";

          "${cfg.config.modifier}+Shift+space" = "floating toggle";
          "${cfg.config.modifier}+space" = "focus mode_toggle";

          "${cfg.config.modifier}+1" = "workspace 1";
          "${cfg.config.modifier}+2" = "workspace 2";
          "${cfg.config.modifier}+3" = "workspace 3";
          "${cfg.config.modifier}+4" = "workspace 4";
          "${cfg.config.modifier}+5" = "workspace 5";
          "${cfg.config.modifier}+6" = "workspace 6";
          "${cfg.config.modifier}+7" = "workspace 7";
          "${cfg.config.modifier}+8" = "workspace 8";
          "${cfg.config.modifier}+9" = "workspace 9";

          "${cfg.config.modifier}+Shift+1" = "move container to workspace 1";
          "${cfg.config.modifier}+Shift+2" = "move container to workspace 2";
          "${cfg.config.modifier}+Shift+3" = "move container to workspace 3";
          "${cfg.config.modifier}+Shift+4" = "move container to workspace 4";
          "${cfg.config.modifier}+Shift+5" = "move container to workspace 5";
          "${cfg.config.modifier}+Shift+6" = "move container to workspace 6";
          "${cfg.config.modifier}+Shift+7" = "move container to workspace 7";
          "${cfg.config.modifier}+Shift+8" = "move container to workspace 8";
          "${cfg.config.modifier}+Shift+9" = "move container to workspace 9";

          "${cfg.config.modifier}+Shift+c" = "reload";
          "${cfg.config.modifier}+Shift+r" = "restart";
          "${cfg.config.modifier}+Shift+e" = "exec i3-nagbar -t warning -m 'Do you want to exit i3?' -b 'Yes' 'i3-msg exit'";

          "${cfg.config.modifier}+r" = "mode resize";
        };
        defaultText = "Default i3 keybindings.";
        description = ''
          An attribute set that assigns a key press to an action using a key symbol.
          See <link xlink:href="https://i3wm.org/docs/userguide.html#keybindings"/>.
          </para><para>
          Consider to use <code>lib.mkOptionDefault</code> function to extend or override
          default keybindings instead of specifying all of them from scratch.
        '';
        example = literalExample ''
          let
            modifier = xsession.windowManager.i3.config.modifier;
          in

          lib.mkOptionDefault {
            "''${modifier}+Return" = "exec i3-sensible-terminal";
            "''${modifier}+Shift+q" = "kill";
            "''${modifier}+d" = "exec \${pkgs.dmenu}/bin/dmenu_run";
          }
        '';
      };

      keycodebindings = mkOption {
        type = types.attrsOf (types.nullOr types.str);
        default = {};
        description = ''
          An attribute set that assigns keypress to an action using key code.
          See <link xlink:href="https://i3wm.org/docs/userguide.html#keybindings"/>.
        '';
        example = { "214" = "exec --no-startup-id /bin/script.sh"; };
      };

      colors = mkOption {
        type = types.submodule {
          options = {
            background = mkOption {
              type = types.str;
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
        type = types.attrsOf (types.attrsOf types.str);
        default = {
          resize = {
            "Left" = "resize shrink width 10 px or 10 ppt";
            "Down" = "resize grow height 10 px or 10 ppt";
            "Up" = "resize shrink height 10 px or 10 ppt";
            "Right" = "resize grow width 10 px or 10 ppt";
            "Escape" = "mode default";
            "Return" = "mode default";
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
              default = "off";
              description = ''
                This option controls whether to disable container borders on
                workspace with a single container.
              '';
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
    mapAttrsToList (keycomb: action: optionalString (action != null) "bindsym ${keycomb} ${action}") keybindings
  );

  keycodebindingsStr = keycodebindings: concatStringsSep "\n" (
    mapAttrsToList (keycomb: action: optionalString (action != null) "bindcode ${keycomb} ${action}") keycodebindings
  );

  colorSetStr = c: concatStringsSep " " [ c.border c.background c.text c.indicator c.childBorder ];
  barColorSetStr = c: concatStringsSep " " [ c.border c.background c.text ];

  criteriaStr = criteria: "[${concatStringsSep " " (mapAttrsToList (k: v: ''${k}="${v}"'') criteria)}]";

  modeStr = name: keybindings: ''
    mode "${name}" {
    ${keybindingsStr keybindings}
    }
  '';

  assignStr = workspace: criteria: concatStringsSep "\n" (
    map (c: "assign ${criteriaStr c} ${workspace}") criteria
  );

  barStr = {
    id, fonts, mode, hiddenState, position, workspaceButtons,
    workspaceNumbers, command, statusCommand, colors, trayOutput, extraConfig, ...
  }: ''
    bar {
      ${optionalString (id != null) "id ${id}"}
      font pango:${concatStringsSep ", " fonts}
      mode ${mode}
      hidden_state ${hiddenState}
      position ${position}
      status_command ${statusCommand}
      i3bar_command ${command}
      workspace_buttons ${if workspaceButtons then "yes" else "no"}
      strip_workspace_numbers ${if !workspaceNumbers then "yes" else "no"}
      tray_output ${trayOutput}
      colors {
        background ${colors.background}
        statusline ${colors.statusline}
        separator ${colors.separator}
        focused_workspace ${barColorSetStr colors.focusedWorkspace}
        active_workspace ${barColorSetStr colors.activeWorkspace}
        inactive_workspace ${barColorSetStr colors.inactiveWorkspace}
        urgent_workspace ${barColorSetStr colors.urgentWorkspace}
        binding_mode ${barColorSetStr colors.bindingMode}
      }
      ${extraConfig}
    }
  '';

  gapsStr = with cfg.config.gaps; ''
    ${optionalString (inner != null) "gaps inner ${toString inner}"}
    ${optionalString (outer != null) "gaps outer ${toString outer}"}
    ${optionalString smartGaps "smart_gaps on"}
    ${optionalString (smartBorders != "off") "smart_borders ${smartBorders}"}
  '';

  floatingCriteriaStr = criteria: "for_window ${criteriaStr criteria} floating enable";
  windowCommandsStr = { command, criteria, ... }: "for_window ${criteriaStr criteria} ${command}";

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
    hide_edge_borders ${window.hideEdgeBorders}
    force_focus_wrapping ${if focus.forceWrapping then "yes" else "no"}
    focus_follows_mouse ${if focus.followMouse then "yes" else "no"}
    focus_on_window_activation ${focus.newWindow}
    mouse_warping ${if focus.mouseWarping then "output" else "none"}
    workspace_layout ${workspaceLayout}

    client.focused ${colorSetStr colors.focused}
    client.focused_inactive ${colorSetStr colors.focusedInactive}
    client.unfocused ${colorSetStr colors.unfocused}
    client.urgent ${colorSetStr colors.urgent}
    client.placeholder ${colorSetStr colors.placeholder}
    client.background ${colors.background}

    ${keybindingsStr keybindings}
    ${keycodebindingsStr keycodebindings}
    ${concatStringsSep "\n" (mapAttrsToList modeStr modes)}
    ${concatStringsSep "\n" (mapAttrsToList assignStr assigns)}
    ${concatStringsSep "\n" (map barStr bars)}
    ${optionalString (gaps != null) gapsStr}
    ${concatStringsSep "\n" (map floatingCriteriaStr floating.criteria)}
    ${concatStringsSep "\n" (map windowCommandsStr window.commands)}
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
        defaultText = literalExample "pkgs.i3";
        example = literalExample "pkgs.i3-gaps";
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
      xdg.configFile."i3/config" = {
        source = configFile;
        onChange = ''
          i3Socket=''${XDG_RUNTIME_DIR:-/run/user/$UID}/i3/ipc-socket.*
          if [ -S $i3Socket ]; then
            echo "Reloading i3"
            $DRY_RUN_CMD ${cfg.package}/bin/i3-msg -s $i3Socket reload 1>/dev/null
          fi
        '';
      };
    }

    (mkIf (cfg.config != null) {
      xsession.windowManager.i3.package = mkDefault (
        if (cfg.config.gaps != null) then pkgs.i3-gaps else pkgs.i3
      );
    })

    (mkIf (cfg.config != null && (any (s: s.workspace != null) cfg.config.startup)) {
      warnings = [
        ("'xsession.windowManager.i3.config.startup.*.workspace' is deprecated, "
          + "use 'xsession.windowManager.i3.config.assigns' instead."
          + "See https://github.com/rycee/home-manager/issues/265.")
      ];
    })
  ]);
}
