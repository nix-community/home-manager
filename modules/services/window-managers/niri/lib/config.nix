{ lib, config, ... }:
let
  inherit (lib) mkOption types mkEnableOption;

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

in
{

}
