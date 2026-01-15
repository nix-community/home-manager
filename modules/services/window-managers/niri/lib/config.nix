{ lib, config, ... }:
let
  inherit (lib)
    mkOption
    types
    mkEnableOption
    flip
    pipe
    filter
    mapAttrsToList
    singleton
    filterAttrs
    ;

  # --- Utilities ---

  # Helper function that forwards values of null and applies a function otherwise
  bindNull = f: v: if v != null then f v else null;

  # Helper function that returns [ ] if null and v otherwise
  #
  # Example:
  # let
  #   a = [ 1 ];
  #   b = null;
  #   c = [ null ];
  # in
  #  assert (valueOrEmptyList a) == [ 1 ];
  #  assert (valueOrEmptyList b) == [ ];
  #  assert (valueOrEmptyList c) == [ null ];
  #  {}
  valueOrEmptyList = v: if v == null then [ ] else v;

  # For the niri config, a value of null is supposed to represent 'unset'.
  # The generator will not write these values out.
  # Example:
  #   nix: border.width = mkNullOption types.ints.unsigned "";
  #   kdl: border { [width <unsigned int>] }
  mkNullOption =
    type: description:
    mkOption {
      type = types.nullOr type;
      default = null;
      inherit description;
    };

  # An option that is either an attrset (options) or unset (null).
  # Example:
  #   nix: touchpad.scrollFactor = mkSubOptions { horizontal = mkNulloption types.float ""; } "";
  #   kdl: touchpad [{ scroll-factor { [horizontal <float>] } }]
  mkSubOptions =
    options: description:
    mkNullOption (types.submodule {
      inherit options;
    }) description;

  # An option that is either set ({}) or unset (null).
  # Example:
  #   nix: touchpad = mkSubOptions { off = mkFlagOption ""; } "";
  #   kdl: touchpad [off]
  mkFlagOption =
    description:
    mkEnableOption description
    // {
      apply = v: if v then { } else null;
    };

  # An option that is either an attrset (props) or unset (null).
  # Example:
  #   nix: length = mkPropOptions { totalProportion = mkNullOption types.float ""; } "";
  #   kdl: length [total-proportion=<float>]
  mkPropOptions =
    props: description:
    mkSubOptions props description
    // {
      apply = bindNull (v: {
        _props = v;
      });
    };

  # An option that is either true, false or unset (null).
  # Use with mkPropOptions.
  # Example:
  #   nix: quit = mkPropOptions { skipConfirmation = mkBoolOption ""; } "";
  #   kdl: quit [skip-confirmation=<true|false>]
  mkBoolOption =
    description:
    mkOption {
      type = types.nullOr types.bool;
      default = null;
      inherit description;
    };

  # --- Option makers ---

  # Helper for gradient options
  mkGradientOption = mkPropOptions {
    from = mkNullOption types.str "'From' value as hex color. [linear-gradient()](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Values/gradient/linear-gradient)";
    to = mkNullOption types.str "'To' value as hex color. [linear-gradient()](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Values/gradient/linear-gradient)";
    angle = mkNullOption types.number "'Angle' value. [linear-gradient()](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Values/gradient/linear-gradient)";
    relativeTo = mkNullOption (types.strMatching "window|workspace-view") "Gradients can be colored relative to windows individually (default or 'window'), or to the whole view of the workspace ('workspace-view').";
  };

  # Common border color options
  borderColorOptions = {
    activeColor = mkNullOption types.str "Active border color.";
    inactiveColor = mkNullOption types.str "Inactive border color.";
    urgentColor = mkNullOption types.str "Urgent border color.";
    activeGradient = mkGradientOption "Active border gradient.";
    inactiveGradient = mkGradientOption "Inactive border gradient.";
    urgentGradient = mkGradientOption "Urgent border gradient.";
  };

  # Helper for border options
  mkBorderOptions = mkSubOptions (
    {
      off = mkFlagOption "Disable border.";
      width = mkNullOption types.ints.unsigned "Width of border in logical pixels.";
    }
    // borderColorOptions
  );

  # Helper for tab indicator options
  mkTabIndicatorOptions = mkSubOptions (
    {
      off = mkFlagOption "Hide the tab indicator.";
      hideWhenSingleTab = mkFlagOption "Hide the indicator for tabbed columns with single window.";
      placeWithinColumn = mkFlagOption "Put the tab indicator within the column, rather than outside.";
      gap = mkNullOption types.int "Gap between the tab indicator and the window in logical pixels.";
      width = mkNullOption types.ints.unsigned "Thickness of the indicator in logical pixels.";
      length = mkPropOptions {
        totalProportion = mkNullOption types.float "Set the `total-proportion property` to make tabs take up this much length relative to the window size.";
      } "Length of the indicator.";
      position = mkNullOption (types.strMatching "left|right|top|bottom") "Position of the tab indicator relative to the window.";
      gapsBetweenTabs = mkNullOption types.ints.unsigned "Gap between individual tabs in logical pixels.";
      cornerRadius = mkNullOption types.ints.unsigned "Rounded corner radius for tabs in the indicator in logical pixels.";
    }
    // borderColorOptions
  );

  # Helper for shadow options
  mkShadowOption =
    isWindowRule:
    mkSubOptions (
      {
        on = mkFlagOption "Enable window shadow.";
        softness = mkNullOption types.ints.unsigned "Shadow softness in logical pixels.";
        spread = mkNullOption types.ints.unsigned "Distance to expand the window rectangle in logical pixels.";
        offset = mkPropOptions {
          x = mkNullOption types.int;
          y = mkNullOption types.int;
        } "Moves the shadow relative to the window in logical pixels.";
        drawBehindWindow = mkFlagOption "Make shadows draw behind the window.";
        color = mkNullOption types.str "Shadow color and opacity.";
        inactiveColor = mkNullOption types.str "Shadow color and opacity for inactive windows.";
      }
      // (
        if isWindowRule then
          {
            off = mkFlagOption "Disable window shadow.";
          }
        else
          { }
      )
    );

  # Helper for matches or excludes
  mkMatchOrExludeOptions =
    isExclude: matchProps: description:
    mkNullOption (types.listOf (
      types.submodule {
        options = matchProps;
      }
    )) description
    // {
      apply = bindNull (
        builtins.map (ruleProps: {
          "${if isExclude then "exclude" else "match"}" = {
            _props = ruleProps;
          };
        })
      );
    };

  # Helper for match rule options
  mkMatchRuleOptions =
    isLayerRule: matchProps: options: description:
    mkOption {
      default = null;
      inherit description;
      type =
        flip pipe
          [
            (v: types.submodule { options = v; })
            types.listOf
            types.nullOr
          ]
          (
            {
              matches = mkMatchOrExludeOptions false matchProps "";
              excludes = mkMatchOrExludeOptions true matchProps "";
            }
            // options
          );
    }
    // {
      apply = bindNull (
        map (v: {
          ${if isLayerRule then "layerRule" else "windowRule"} = {
            _children = (valueOrEmptyList v.matches) ++ (valueOrEmptyList v.excludes);
          }
          // (builtins.removeAttrs v [
            "matches"
            "excludes"
          ]);
        })
      );
    };

  # --- Config Options ---

  # keyboard options
  keyboardOptions = {
    xkb = mkNullOption (types.attrsOf types.str) "See the `xkeyboard-config(7)` manual for more information.";
    trackLayout = mkNullOption (types.strMatching "global|window") "Remember current layout globally or per-window.";
    repeatDelay = mkNullOption types.numbers.positive "Delay in milliseconds before the keyboard repeat starts.";
    repeatRate = mkNullOption types.numbers.positive "Repeat rate in characters per second.";
    numlock = mkFlagOption "Turn on Num Lock automatically at startup.";
  };

  # touchpad options
  touchpadOptions = {
    off = mkFlagOption "Don't send events from this device.";
    naturalScroll = mkFlagOption "Inverts the scrolling direction.";
    accelSpeed = mkNullOption (types.numbers.between (-1.0) 1.0) "Pointer acceleration speed.";
    accelProfile = mkNullOption (types.strMatching "adaptive|flat") "Can be `adaptive` (the default) or `flat` (disables pointer acceleration).";
    scrollMethod = mkNullOption (types.strMatching "no-scroll|two-finger|edge|on-button-down") "When to generate scroll events instead of pointer motion events.";
    scrollButton = mkNullOption types.str "The button code used for the `on-button-down` scroll method. You can find it in `libinput debug-events`.";
    scrollButtonLock = mkFlagOption "When enabled, the button does not need to be held down.";
    leftHanded = mkFlagOption "Enable left-handed mode.";
    middleEmulation = mkFlagOption "Emulate a middle mouse click by pressing left and right mouse buttons at once.";
    tap = mkFlagOption "Tap-to-click.";
    dwt = mkFlagOption "Disable-when-typing.";
    dwtp = mkFlagOption "Disable-when-trackpointing.";
    drag = mkFlagOption "Enable tap-and-drag.";
    dragLock = mkFlagOption "If set, lifting the finger off for a short time while dragging will not drop the dragged item.";
    tapButtonMap = mkNullOption (types.strMatching "left-right-middle|left-middle-right") "Controls which button corresponds to a two-finger tap and a three-finger tap.";
    clickMethod = mkNullOption (types.strMatching "button-areas|clickfinger") "Changes the click method.";
    disabledOnExternalMouse = mkFlagOption "Do not send events while external pointer device is plugged in.";
    scrollFactor = mkSubOptions {
      horizontal = mkNullOption types.float "Horizontal scale.";
      vertical = mkNullOption types.float "Vertical scale.";
    } "Scales the scrolling speed.";
  };

  # mouse options
  mouseOptions = {
    off = mkFlagOption "Don't send events from this device.";
    naturalScroll = mkFlagOption "Inverts the scrolling direction.";
    accelSpeed = mkNullOption (types.numbers.between (-1.0) 1.0) "Pointer acceleration speed.";
    accelProfile = mkNullOption (types.strMatching "adaptive|flat") "Can be `adaptive` (the default) or `flat` (disables pointer acceleration).";
    scrollMethod = mkNullOption (types.strMatching "no-scroll|two-finger|edge|on-button-down") "When to generate scroll events instead of pointer motion events.";
    scrollButton = mkNullOption types.str "The button code used for the `on-button-down` scroll method. You can find it in `libinput debug-events`.";
    scrollButtonLock = mkFlagOption "When enabled, the button does not need to be held down.";
    leftHanded = mkFlagOption "Enable left-handed mode.";
    middleEmulation = mkFlagOption "Emulate a middle mouse click by pressing left and right mouse buttons at once.";
    scrollFactor = mkSubOptions {
      horizontal = mkNullOption types.float "Horizontal scale.";
      vertical = mkNullOption types.float "Vertical scale.";
    } "Scales the scrolling speed.";
  };

  # trackpoint options
  trackpointOptions = {
    off = mkFlagOption "Don't send events from this device.";
    naturalScroll = mkFlagOption "Inverts the scrolling direction.";
    accelSpeed = mkNullOption (types.numbers.between (-1.0) 1.0) "Pointer acceleration speed.";
    accelProfile = mkNullOption (types.strMatching "adaptive|flat") "Can be `adaptive` (the default) or `flat` (disables pointer acceleration).";
    scrollMethod = mkNullOption (types.strMatching "no-scroll|two-finger|edge|on-button-down") "When to generate scroll events instead of pointer motion events.";
    scrollButton = mkNullOption types.str "The button code used for the `on-button-down` scroll method. You can find it in `libinput debug-events`.";
    scrollButtonLock = mkFlagOption "When enabled, the button does not need to be held down.";
    leftHanded = mkFlagOption "Enable left-handed mode.";
    middleEmulation = mkFlagOption "Emulate a middle mouse click by pressing left and right mouse buttons at once.";
  };

  # trackball options
  trackballOptions = {
    off = mkFlagOption "Don't send events from this device.";
    naturalScroll = mkFlagOption "Inverts the scrolling direction.";
    accelSpeed = mkNullOption (types.numbers.between (-1.0) 1.0) "Pointer acceleration speed.";
    accelProfile = mkNullOption (types.strMatching "adaptive|flat") "Can be `adaptive` (the default) or `flat` (disables pointer acceleration).";
    scrollMethod = mkNullOption (types.strMatching "no-scroll|two-finger|edge|on-button-down") "When to generate scroll events instead of pointer motion events.";
    scrollButton = mkNullOption types.str "The button code used for the `on-button-down` scroll method. You can find it in `libinput debug-events`.";
    scrollButtonLock = mkFlagOption "When enabled, the button does not need to be held down.";
    leftHanded = mkFlagOption "Enable left-handed mode.";
    middleEmulation = mkFlagOption "Emulate a middle mouse click by pressing left and right mouse buttons at once.";
  };

  # tablet options
  tabletOptions = {
    off = mkFlagOption "Don't send events from this device.";
    calibrationMatrix =
      mkNullOption (types.addCheck (types.listOf types.float) (vs: (builtins.length vs) == 6))
        "See the [LIBINPUT_CALIBRATION_MATRIX documentation](https://wayland.freedesktop.org/libinput/doc/latest/device-configuration-via-udev.html) for examples.";
    mapToOutput = mkNullOption types.str "Map input device to specific output.";
  };

  # touch options
  touchOptions = {
    off = mkFlagOption "Don't send events from this device.";
    calibrationMatrix =
      mkNullOption (types.addCheck (types.listOf types.float) (vs: (builtins.length vs) == 6))
        "See the [LIBINPUT_CALIBRATION_MATRIX documentation](https://wayland.freedesktop.org/libinput/doc/latest/device-configuration-via-udev.html) for examples.";
    mapToOutput = mkNullOption types.str "Map input device to specific output.";
  };

  # input options
  inputOptions = {
    keyboard = mkSubOptions keyboardOptions "Keyboard options.";
    touchpad = mkSubOptions touchpadOptions "Touchpad options.";
    mouse = mkSubOptions mouseOptions "Mouse options.";
    trackpoint = mkSubOptions trackpointOptions "Trackpoint options.";
    trackball = mkSubOptions trackballOptions "Trackball options.";
    tablet = mkSubOptions tabletOptions "Tablet options.";
    touch = mkSubOptions touchOptions "Touch options.";
    disablePowerKeyHandling = mkFlagOption "Set this if you would like to configure the power button elsewhere (i.e. logind.conf).";
    warpMouseToFocus = mkSubOptions {
      mode = mkNullOption (types.strMatching "center-xy|center-xy-always") ''
        Can be one of 'center-xy' or 'center-xy-always'.
        + 'center-xy' warps by both X and Y coordinates together. So if the mouse was anywhere outside the newly focused window, it will warp to the center of the window.
        + 'center-xy-always' warps by both X and Y coordinates together, even if the mouse was already somewhere inside the newly focused window.
      '';
    } "Makes the mouse warp to newly focused windows";
    focusFollowsMouse = mkSubOptions {
      maxScrollAmount = mkNullOption (types.numbers.nonnegative) null // {
        apply = bindNull (t: "${t}%");
        description = "Don't focus a window if it will result in the view scrolling more than the set amount.";
      };
    } "Focuses windows and outputs automatically when moving the mouse over them.";
    workspaceAutoBackAndForth = mkFlagOption "If this flag is enabled, switching to the same workspace by index twice will switch back to the previous workspace.";
    modKey = mkNullOption (types.strMatching "Super|Alt|Mod3|Mod5|Ctrl|Shift") "Customize the 'Mod' key for key bindings. Only valid modifiers are allowed, e.g. Super, Alt, Mod3, Mod5, Ctrl, Shift.";
    modKeyNested = mkNullOption (types.strMatching "Super|Alt|Mod3|Mod5|Ctrl|Shift") "Same as modKey but for nested sessions.";
  };

  # layout options
  layoutOptions =
    let
      # per-output layer options can disable options by setting them to false
      mkLayoutBoolOption =
        description:
        (mkBoolOption description)
        // {
          apply = bindNull (v: if v then { } else false);
        };

      # helper type for distances
      mkDistanceOptions =
        description:
        (mkNullOption (types.listOf (
          types.attrTag {
            none = mkOption { type = types.submodule { }; };
            proportion = mkOption {
              type = types.numbers.nonnegative;
            };
            fixed = mkOption {
              type = types.ints.unsigned;
            };
          }
        )) description)
        // {
          apply = bindNull (v: {
            _children = v;
          });
        };

    in
    {
      gaps = mkNullOption types.numbers.nonnegative "Gaps around (inside and outside) windows in logical pixels.";
      centerFocusedColumn = mkNullOption (types.strMatching "never|always|on-overflow") "When to center a column when changing focus.";
      alwaysCenterSingleColumn = mkLayoutBoolOption "Always center a single column on a workspace, regardless of the `center-focused-column` option.";
      emptyWorkspaceAboveFirst = mkLayoutBoolOption "Always add an empty workspace at the very start, in addition to the empty workspace at the very end.";
      defaultColumnDisplay = mkNullOption (types.strMatching "normal|tabbed") "Default display mode for new columns.";
      presetColumnWidths = mkDistanceOptions "Set the widths that the `switch-preset-column-width` action toggles between.";
      defaultColumnWidth = mkDistanceOptions "Default width of new windows.";
      presetWindowHeights = mkDistanceOptions "Set the heights that the `switch-preset-window-height` action toggles between.";
      focusRing = mkBorderOptions "Options for focus rings. A focus ring is drawn only around the active window.";
      border = mkBorderOptions "Options for borders. Borders are drawn around all windows.";
      shadow = mkShadowOption false "Shadow rendered behind a window.";
      tabIndicator = mkTabIndicatorOptions "Appearance of the tab indicator.";
      insertHint = mkSubOptions {
        color = mkNullOption types.str "Color options for insert hint.";
        gradient = mkGradientOption "Gradient options for insert hint.";
      } "Settings for the window insert position hint during an interactive window move.";
      struts =
        mkSubOptions
          {
            left = mkNullOption types.number "Left strut rounded to physical pixels according to scale.";
            right = mkNullOption types.number "Right strut rounded to physical pixels according to scale.";
            top = mkNullOption types.number "Top strut rounded to physical pixels according to scale.";
            bottom = mkNullOption types.number "Bottom strut rounded to physical pixels according to scale.";
          }
          "Shrink the area occupied by windows, similarly to layer-shell panels. You can think of them as a kind of outer gaps. They are set in logical pixels.";
      backgroundColor = mkNullOption types.str "Default background color that niri draws for workspaces.";
    };

  # per-output options
  perOutputOptions = {
    off = mkFlagOption "Turn off that output entirely.";
    mode = mkNullOption (types.strMatching "^[0-9]+x[0-9]+(@[0-9]+(\\.[0-9]*)?)?$") null // {
      description = "Set the monitor resolution and refresh rate.";
      example = "1920x1080@120.030";
    };
    scale = mkNullOption (types.float) "Set the scale of the monitor.";
    transform = mkNullOption (types.strMatching "normal|90|180|270|flipped|flipped-90|flipped-180|flipped-270") "Rotate the output counter-clockwise.";
    position =
      mkSubOptions {
        x = mkNullOption (types.ints.unsigned) "X position.";
        y = mkNullOption (types.ints.unsigned) "Y position.";
      } "Set the position of the output in the global coordinate space."
      // {
        apply = bindNull (t: {
          _props = {
            inherit (t) x y;
          };
        });
      };
    variableRefreshRate = mkFlagOption "Enable variable refresh rate.";
    focusAtStartup = mkFlagOption "Focus this output by default when niri starts.";
    backgroundColor = mkNullOption types.str "Set the background color that niri draws for workspaces on this output.";
    backdropColor = mkNullOption types.str "Set the backdrop color that niri draws for this output.";
    hotCorners = mkSubOptions {
      off = mkFlagOption "Turn off hot corners.";
      topLeft = mkFlagOption "";
      topRight = mkFlagOption "";
      bottomLeft = mkFlagOption "";
      bottomRight = mkFlagOption "";
    } "Customize the hot corners for this output.";
    layout = mkSubOptions layoutOptions "Customize layout settings for an output.";
  };

  # bind options
  bindOptions = {
    repeat = mkBoolOption "Enable or disable repeat.";
    cooldownMs = mkNullOption types.ints.unsigned "Cooldown for repeat.";
    hotkeyOverlayTitle = mkNullOption types.str "Add a bind to the hotkey overlay. Set to `null` to remove a hardcoded binding.";
    allowInhibiting = mkBoolOption "Set to `false` to disallow inhibiting.";
    allowWhenLocked = mkBoolOption "Allow using a spawn binding even when locked.";
    action =
      let
        mkPlainActionOption = mkNullOption (types.submodule { });
        mkArgActionOption =
          options: argName: description:
          mkSubOptions options description
          // {
            apply = bindNull (v: {
              _props = builtins.removeAttrs v [ argName ];
              _args = bindNull singleton v.${argName};
            });
          };
        mkWorkspaceOption = mkNullOption (types.either types.ints.unsigned types.str);
      in
      mkOption {
        type = types.attrTag {
          quit = mkPropOptions {
            skipConfirmation = mkBoolOption "Don't show confirmation dialog.";
          } "Exit niri";
          suspend = mkPlainActionOption "Suspend the session.";
          powerOffMonitors = mkPlainActionOption "Power off all monitors via DPMS.";
          powerOnMonitors = mkPlainActionOption "Power on all monitors via DPMS.";
          spawn =
            mkSubOptions {
              command = mkNullOption (types.listOf types.str) "The command and its arguments.";
            } "Spawn a command."
            // {
              apply = bindNull (v: {
                _args = v.command;
              });
            };
          spawnSh = mkArgActionOption {
            command = mkNullOption types.str "The command string, passed to `sh -c`.";
          } "command" "Spawn a command through the shell";
          doScreenTransition = mkPropOptions {
            delayMs = mkNullOption types.ints.unsigned "Delay in ms.";
          } "Do a screen transition";
          screenshot = mkPropOptions {
            writeToDisk = mkBoolOption "Save the screenshot in the screenshot directory.";
            showPointer = mkBoolOption "Show the pointer as part of the screenshot.";
          } "Open the screenshot UI.";
          screenshotScreen = mkPropOptions {
            writeToDisk = mkBoolOption "Save the screenshot in the screenshot directory.";
            showPointer = mkBoolOption "Show the pointer as part of the screenshot.";
          } "Screenshot the focused screen.";
          screenshotWindow = mkPropOptions {
            writeToDisk = mkBoolOption "Save the screenshot in the screenshot directory.";
            showPointer = mkBoolOption "Show the pointer as part of the screenshot.";
          } "Screenshot the focused window.";
          toggleKeyboardShortcutsInhibit = mkPlainActionOption "Toggle the keyboard shortcuts inhibitor (if any) for the focused surface.";
          closeWindow = mkPlainActionOption "Close the focused window.";
          fullscreenWindow = mkPlainActionOption "Toggle fullscreen on the focused window.";
          toggleWindowedFullscreen = mkPlainActionOption "Toggle windowed (fake) fullscreen on the focused window.";
          focusWindowInColumn = mkArgActionOption {
            index = mkNullOption types.ints.unsigned "Index in column.";
          } "index" "Focus a window in the focused column by index.";
          focusWindowPrevious = mkPlainActionOption "Focus the previously focused window.";
          focusColumnLeft = mkPlainActionOption "Focus the column to the left.";
          focusColumnRight = mkPlainActionOption "Focus the column to the right.";
          focusColumnFirst = mkPlainActionOption "Focus the first column.";
          focusColumnLast = mkPlainActionOption "Focus the last column.";
          focusColumnRightOrFirst = mkPlainActionOption "Focus the next column to the right, looping if at end.";
          focusColumnLeftOrLast = mkPlainActionOption "Focus the next column to the left, looping if at start.";
          focusColumn = mkArgActionOption {
            index = mkNullOption types.ints.unsigned "Index of column.";
          } "index" "Focus a column by index.";
          focusWindowOrMonitorUp = mkPlainActionOption "Focus the window or the monitor above.";
          focusWindowOrMonitorDown = mkPlainActionOption "Focus the window or the monitor below.";
          focusColumnOrMonitorLeft = mkPlainActionOption "Focus the column or the monitor to the left.";
          focusColumnOrMonitorRight = mkPlainActionOption "Focus the column or the monitor to the right.";
          focusWindowDown = mkPlainActionOption "Focus the window below.";
          focusWindowUp = mkPlainActionOption "Focus the window above.";
          focusWindowDownOrColumnLeft = mkPlainActionOption "Focus the window below or the column to the left.";
          focusWindowDownOrColumnRight = mkPlainActionOption "Focus the window below or the column to the right.";
          focusWindowUpOrColumnLeft = mkPlainActionOption "Focus the window above or the column to the left.";
          focusWindowUpOrColumnRight = mkPlainActionOption "Focus the window above or the column to the right.";
          focusWindowOrWorkspaceDown = mkPlainActionOption "Focus the window or the workspace below.";
          focusWindowOrWorkspaceUp = mkPlainActionOption "Focus the window or the workspace above.";
          focusWindowTop = mkPlainActionOption "Focus the topmost window.";
          focusWindowBottom = mkPlainActionOption "Focus the bottommost window.";
          focusWindowDownOrTop = mkPlainActionOption "Focus the window below or the topmost window.";
          focusWindowUpOrBottom = mkPlainActionOption "Focus the window above or the bottommost window.";
          moveColumnLeft = mkPlainActionOption "Move the focused column to the left.";
          moveColumnRight = mkPlainActionOption "Move the focused column to the right.";
          moveColumnToFirst = mkPlainActionOption "Move the focused column to the start of the workspace.";
          moveColumnToLast = mkPlainActionOption "Move the focused column to the end of the workspace.";
          moveColumnLeftOrToMonitorLeft = mkPlainActionOption "Move the focused column to the left or to the monitor to the left.";
          moveColumnRightOrToMonitorRight = mkPlainActionOption "Move the focused column to the right or to the monitor to the right.";
          moveColumnToIndex = mkArgActionOption {
            index = mkNullOption types.ints.unsigned "Index to move to.";
          } "index" "Move the focused column to a specific index on its workspace.";
          moveWindowDown = mkPlainActionOption "Move the focused window down in a column.";
          moveWindowUp = mkPlainActionOption "Move the focused window up in a column.";
          moveWindowDownOrToWorkspaceDown = mkPlainActionOption "Move the focused window down in a column or to the workspace below.";
          moveWindowUpOrToWorkspaceUp = mkPlainActionOption "Move the focused window up in a column or to the workspace above.";
          consumeOrExpelWindowLeft = mkPlainActionOption "Consume or expel the focused window left.";
          consumeOrExpelWindowRight = mkPlainActionOption "Consume or expel the focused window right.";
          consumeWindowIntoColumn = mkPlainActionOption "Consume the window to the right into the focused column.";
          expelWindowFromColumn = mkPlainActionOption "Expel the focused window from the column.";
          swapWindowRight = mkPlainActionOption "Swap focused window with one to the right.";
          swapWindowLeft = mkPlainActionOption "Swap focused window with one to the left.";
          toggleColumnTabbedDisplay = mkPlainActionOption "Toggle the focused column between normal and tabbed display.";
          setColumnDisplay = mkArgActionOption {
            columnDisplay = mkNullOption (types.strMatching "normal|tabbed") "";
          } "columnDisplay" "Set the display mode of the focused column.";
          centerColumn = mkPlainActionOption "Center the focused column on the screen.";
          centerWindow = mkPlainActionOption "Center the focused window on the screen.";
          centerVisibleColumns = mkPlainActionOption "Center all fully visible columns on the screen.";
          focusWorkspaceDown = mkPlainActionOption "Focus the workspace below.";
          focusWorkspaceUp = mkPlainActionOption "Focus the workspace above.";
          focusWorkspace = mkArgActionOption {
            workspace = mkWorkspaceOption "Workspace to focus.";
          } "workspace" "Focus a workspace by reference (index or name).";
          focusWorkspacePrevious = mkPlainActionOption "Focus the previous workspace.";
          moveWindowToWorkspaceDown = mkPropOptions {
            focus = mkBoolOption "Follow the window.";
          } "Move the focused window down in a column.";
          moveWindowToWorkspaceUp = mkPropOptions {
            focus = mkBoolOption "Follow the window.";
          } "Move the focused window up in a column.";
          moveWindowToWorkspace = mkArgActionOption {
            workspace = mkWorkspaceOption "Workspace to move to.";
            focus = mkBoolOption "Follow the window.";
          } "workspace" "Move the focused window down in a column or to the workspace below.";
          moveColumnToWorkspaceDown = mkPropOptions {
            focus = mkBoolOption "";
          } "";
          moveColumnToWorkspaceUp = mkPropOptions {
            focus = mkBoolOption "";
          } "";
          moveColumnToWorkspace = mkArgActionOption {
            workspace = mkWorkspaceOption "";
            focus = mkBoolOption "";
          } "workspace" "";
          moveWorkspaceDown = mkPlainActionOption "";
          moveWorkspaceUp = mkPlainActionOption "";
          moveWorkspaceToIndex = mkArgActionOption {
            index = mkNullOption types.ints.unsigned "";
          } "index" "";
          setWorkspaceName = mkArgActionOption {
            name = mkNullOption types.str "";
          } "name" "";
          unsetWorkspaceName = mkPlainActionOption "";
          focusMonitorLeft = mkPlainActionOption "";
          focusMonitorRight = mkPlainActionOption "";
          focusMonitorDown = mkPlainActionOption "";
          focusMonitorUp = mkPlainActionOption "";
          focusMonitorPrevious = mkPlainActionOption "";
          focusMonitorNext = mkPlainActionOption "";
          focusMonitor = mkArgActionOption {
            monitor = mkNullOption types.str "";
          } "monitor" "";
          moveWindowToMonitorLeft = mkPlainActionOption "";
          moveWindowToMonitorRight = mkPlainActionOption "";
          moveWindowToMonitorDown = mkPlainActionOption "";
          moveWindowToMonitorUp = mkPlainActionOption "";
          moveWindowToMonitorPrevious = mkPlainActionOption "";
          moveWindowToMonitorNext = mkPlainActionOption "";
          moveWindowToMonitor = mkArgActionOption {
            monitor = mkNullOption types.str "";
          } "monitor" "";
          moveColumnToMonitorLeft = mkPlainActionOption "";
          moveColumnToMonitorRight = mkPlainActionOption "";
          moveColumnToMonitorDown = mkPlainActionOption "";
          moveColumnToMonitorUp = mkPlainActionOption "";
          moveColumnToMonitorPrevious = mkPlainActionOption "";
          moveColumnToMonitorNext = mkPlainActionOption "";
          moveColumnToMonitor = mkArgActionOption {
            monitor = mkNullOption types.str "";
          } "monitor" "";
          setWindowWidth = mkArgActionOption {
            width = mkNullOption types.str "";
          } "width" "";
          setWindowHeight = mkArgActionOption {
            height = mkNullOption types.str "";
          } "height" "";
          resetWindowHeight = mkPlainActionOption "";
          switchPresetColumnWidth = mkPlainActionOption "";
          switchPresetColumnWidthBack = mkPlainActionOption "";
          switchPresetWindowWidth = mkPlainActionOption "";
          switchPresetWindowWidthBack = mkPlainActionOption "";
          switchPresetWindowHeight = mkPlainActionOption "";
          switchPresetWindowHeightBack = mkPlainActionOption "";
          maximizeColumn = mkPlainActionOption "";
          maximizeWindowToEdges = mkPlainActionOption "";
          setColumnWidth = mkArgActionOption {
            width = mkNullOption types.str "";
          } "width" "";
          expandColumnToAvailableWidth = mkPlainActionOption "";
          switchLayout = mkArgActionOption {
            layout = mkNullOption (types.either types.ints.unsigned (types.strMatching "next|prev")) "" // {
              apply = bindNull builtins.toString;
            };
          } "layout" "";
          showHotkeyOverlay = mkPlainActionOption "";
          moveWorkspaceToMonitorLeft = mkPlainActionOption "";
          moveWorkspaceToMonitorRight = mkPlainActionOption "";
          moveWorkspaceToMonitorDown = mkPlainActionOption "";
          moveWorkspaceToMonitorUp = mkPlainActionOption "";
          moveWorkspaceToMonitorPrevious = mkPlainActionOption "";
          moveWorkspaceToMonitorNext = mkPlainActionOption "";
          moveWorkspaceToMonitor = mkArgActionOption {
            monitor = mkNullOption types.str "";
          } "monitor" "";
          toggleDebugTint = mkPlainActionOption "";
          debugToggleOpaqueRegions = mkPlainActionOption "";
          debugToggleDamage = mkPlainActionOption "";
          toggleWindowFloating = mkPlainActionOption "";
          moveWindowToFloating = mkPlainActionOption "";
          moveWindowToTiling = mkPlainActionOption "";
          focusFloating = mkPlainActionOption "";
          focusTiling = mkPlainActionOption "";
          switchFocusBetweenFloatingAndTiling = mkPlainActionOption "";
          moveFloatingWindow = mkPropOptions {
            x = mkNullOption types.int "";
            y = mkNullOption types.int "";
          } "";
          toggleWindowRuleOpacity = mkPlainActionOption "";
          setDynamicCastWindow = mkPlainActionOption "";
          setDynamicCastMonitor = mkArgActionOption {
            monitor = mkNullOption types.str "";
          } "monitor" "";
          clearDynamicCastTarget = mkPlainActionOption "";
          toggleOverview = mkPlainActionOption "";
          openOverview = mkPlainActionOption "";
          closeOverview = mkPlainActionOption "";
        };
      };
  };
in
{
  options = {
    input = mkSubOptions inputOptions "Input options.";
    layout = mkSubOptions layoutOptions "Layout options.";
    outputs = mkNullOption (types.attrsOf (types.submodule { options = perOutputOptions; })) null // {
      description = "Output options.";
      apply = bindNull (
        mapAttrsToList (
          name: value: {
            output = value // {
              _args = [ name ];
            };
          }
        )
      );
    };
    binds = mkNullOption (types.attrsOf (types.submodule { options = bindOptions; })) null // {
      description = "Bind options.";
      apply = bindNull (
        builtins.mapAttrs (
          n: v: {
            # don't rename bind keys
            _preserve_name = { };

            # preserve null for hotkeyOverlayTitle and remove action
            _props = (filterAttrs (n: v: n != "action" && (n == "hotkeyOverlayTitle" || v != null)) v) // {
              _preserve_null = { };
            };

            _children = [ v.action ];
          }
        )
      );
    };
  };
}
