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
in
{
  options = {
    input = mkSubOptions inputOptions "Input options.";
  };
}
