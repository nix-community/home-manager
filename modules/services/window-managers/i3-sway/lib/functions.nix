{ cfg, lib, moduleName }:

with lib;

rec {
  criteriaStr = criteria:
    "[${
      concatStringsSep " " (mapAttrsToList (k: v: ''${k}="${v}"'') criteria)
    }]";

  keybindingsStr = keybindings:
    concatStringsSep "\n" (mapAttrsToList (keycomb: action:
      optionalString (action != null) "bindsym ${
        lib.optionalString (moduleName == "sway") "--to-code "
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
    ${keybindingsStr keybindings}
    }
  '';

  assignStr = workspace: criteria:
    concatStringsSep "\n"
    (map (c: "assign ${criteriaStr c} ${workspace}") criteria);

  barStr = { id, fonts, mode, hiddenState, position, workspaceButtons
    , workspaceNumbers, command, statusCommand, colors, trayOutput, extraConfig
    , ... }: ''
      bar {
        ${optionalString (id != null) "id ${id}"}
        font pango:${concatStringsSep ", " fonts}
        mode ${mode}
        hidden_state ${hiddenState}
        position ${position}
        ${
          optionalString (statusCommand != null)
          "status_command ${statusCommand}"
        }
        ${moduleName}bar_command ${command}
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
