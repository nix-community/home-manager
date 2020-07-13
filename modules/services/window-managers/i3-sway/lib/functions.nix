{ cfg, lib, moduleName }:

with lib;

rec {
  criteriaStr = criteria:
    "[${
      concatStringsSep " " (mapAttrsToList (k: v: ''${k}="${v}"'') criteria)
    }]";

  keybindingsStr = { keybindings, bindsymArgs ? "" }:
    concatStringsSep "\n" (mapAttrsToList (keycomb: action:
      optionalString (action != null) "bindsym ${
        lib.optionalString (bindsymArgs != "") "${bindsymArgs} "
      }${keycomb} ${action}") keybindings);

  keycodebindingsStr = keycodebindings:
    concatStringsSep "\n" (mapAttrsToList (keycomb: action:
      optionalString (action != null) "bindcode ${keycomb} ${action}")
      keycodebindings);

  colorSetStr = c:
    concatStringsSep " " [
      c.border
      c.background
      c.text
      c.indicator
      c.childBorder
    ];
  barColorSetStr = c: concatStringsSep " " [ c.border c.background c.text ];

  modeStr = name: keybindings: ''
    mode "${name}" {
    ${keybindingsStr { inherit keybindings; }}
    }
  '';

  assignStr = workspace: criteria:
    concatStringsSep "\n"
    (map (c: "assign ${criteriaStr c} ${workspace}") criteria);

  barStr = { id, fonts, mode, hiddenState, position, workspaceButtons
    , workspaceNumbers, command, statusCommand, colors, trayOutput, extraConfig
    , ... }:
    let colorsNotNull = lib.filterAttrs (n: v: v != null) colors != { };
    in ''
      bar {
        ${optionalString (id != null) "id ${id}"}
        ${
          optionalString (fonts != [ ])
          "font pango:${concatStringsSep ", " fonts}"
        }
        ${optionalString (mode != null) "mode ${mode}"}
        ${optionalString (hiddenState != null) "hidden_state ${hiddenState}"}
        ${optionalString (position != null) "position ${position}"}
        ${
          optionalString (statusCommand != null)
          "status_command ${statusCommand}"
        }
        ${moduleName}bar_command ${command}
        ${
          optionalString (workspaceButtons != null)
          "workspace_buttons ${if workspaceButtons then "yes" else "no"}"
        }
        ${
          optionalString (workspaceNumbers != null)
          "strip_workspace_numbers ${if !workspaceNumbers then "yes" else "no"}"
        }
        ${optionalString (trayOutput != null) "tray_output ${trayOutput}"}
        ${optionalString colorsNotNull "colors {"}
          ${
            optionalString (colors.background != null)
            "background ${colors.background}"
          }
          ${
            optionalString (colors.statusline != null)
            "statusline ${colors.statusline}"
          }
          ${
            optionalString (colors.separator != null)
            "separator ${colors.separator}"
          }
          ${
            optionalString (colors.focusedWorkspace != null)
            "focused_workspace ${barColorSetStr colors.focusedWorkspace}"
          }
          ${
            optionalString (colors.activeWorkspace != null)
            "active_workspace ${barColorSetStr colors.activeWorkspace}"
          }
          ${
            optionalString (colors.inactiveWorkspace != null)
            "inactive_workspace ${barColorSetStr colors.inactiveWorkspace}"
          }
          ${
            optionalString (colors.urgentWorkspace != null)
            "urgent_workspace ${barColorSetStr colors.urgentWorkspace}"
          }
          ${
            optionalString (colors.bindingMode != null)
            "binding_mode ${barColorSetStr colors.bindingMode}"
          }
        ${optionalString colorsNotNull "}"}
        ${extraConfig}
      }
    '';

  gapsStr = with cfg.config.gaps; ''
    ${optionalString (inner != null) "gaps inner ${toString inner}"}
    ${optionalString (outer != null) "gaps outer ${toString outer}"}
    ${optionalString (horizontal != null)
    "gaps horizontal ${toString horizontal}"}
    ${optionalString (vertical != null) "gaps vertical ${toString vertical}"}
    ${optionalString (top != null) "gaps top ${toString top}"}
    ${optionalString (bottom != null) "gaps bottom ${toString bottom}"}
    ${optionalString (left != null) "gaps left ${toString left}"}
    ${optionalString (right != null) "gaps right ${toString right}"}

    ${optionalString smartGaps "smart_gaps on"}
    ${optionalString (smartBorders != "off") "smart_borders ${smartBorders}"}
  '';

  floatingCriteriaStr = criteria:
    "for_window ${criteriaStr criteria} floating enable";
  windowCommandsStr = { command, criteria, ... }:
    "for_window ${criteriaStr criteria} ${command}";
}
