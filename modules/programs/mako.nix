{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.mako;

in {
  options = {
    programs.mako = {
      enable = mkEnableOption "Mako, lightweight notification daemon for Wayland";

      maxVisible = mkOption {
        default = 5;
        type = types.nullOr types.int;
        description = ''
          Set maximum number of visible notifications. Set -1 to show all.
        '';
      };

      sort = mkOption {
        default = "-time";
        type = types.nullOr types.str;
        description = ''
	  Sorts incoming notifications by time and/or priority in ascending(+) or descending(-( order. E.g.: +/-time, +/-priority
	'';
      };

      output = mkOption {
        default = null;
        type = types.nullOr types.str;
        description = ''
	   Show notifications on the specified output. If empty, notifications will appear on the focused output.
	   Requires the compositor to support the Wayland protocol xdg-output-unstable-v1 version 2.
        '';
      };

      layer = mkOption {
        default = "top";
        type = types.nullOr (types.enum [ "background" "bottom" "top" "overlay" ]);
        description = ''
	   Arrange mako at the specified layer, relative to normal windows. Supported values are background, bottom, top, and overlay. Using overlay will cause notifications to be displayed above fullscreen windows, though this may also occur at top depending on your compositor.
        '';
      };

      anchor = mkOption {
        default = "top-right";
        type = types.nullOr (types.enum [ "top-right" "tio.center" "top-left" "bottom-right" "bottom-center" "bottom-left" "center" ]);
        description = ''
           Show notifications at the specified position on the output. Supported values are top-right, top-center, top-left, bottom-right, bottom-center, bottom-left, and center.
         '';
      };

      font = mkOption {
        default = "monospace 10";
        type = types.nullOr types.str;
        description = ''
	   Set font to font, in Pango format.
        '';
      };

      backgroundColor = mkOption {
        default = "#285577FF";
        type = types.nullOr types.str;
        description = ''
	   Set background color to color. See COLORS for more information.
        '';
      };

      textColor = mkOption {
        default = "#FFFFFFFF";
        type = types.nullOr types.str;
        description = ''
	   Set text color to color. See COLORS for more information.
        '';
      };

      width = mkOption {
        default = 300;
        type = types.nullOr types.int;
        description = ''
	   Set width of notification popups.
        '';
      };

      height = mkOption {
        default = 100;
        type = types.nullOr types.int;
        description = ''
           Set maximum height of notification popups. Notifications whose text takes up less space are shrunk to fit.
        '';
      };

      margin = mkOption {
        default = 10;
        type = types.nullOr types.int;
        description = ''
           Set margin of each edge to the size specified by directional.
	   See DIRECTIONAL VALUES for more information.
        '';
      };

      padding = mkOption {
        default = 5;
        type = types.nullOr types.int;
        description = ''
	   Set padding on each side to the size specified by directional.
           See DIRECTIONAL VALUES for more information.
        '';
      };

      borderSize = mkOption {
        default = 1;
        type = types.nullOr types.int;
        description = ''
           Set popup border size to px pixels.
        '';
      };

      borderColor = mkOption {
        default = "#4C7899FF";
        type = types.nullOr types.str;
        description = ''
           Set popup border color to color. See COLORS for more information.
        '';
      };

      borderRadius = mkOption {
        default = 0;
        type = types.nullOr types.int;
        description = ''
	   Set popup corner radius to px pixels.
        '';
      };

      progressColor = mkOption {
        default = "over #5588AAFF";
        type = types.nullOr types.str;
        description = ''
           Set popup progress indicator color to color. See COLOR for more information. To draw the progress indicator on top of the background color, use the over attribute. To replace the background color, use the source attribute (this can be useful when the notification is semi-transparent).
        '';
      };

      icons = mkOption {
        default = 1;
        type = types.nullOr types.bool;
        description = ''
	   Show icons in notifications.
        '';
      };

      maxIconSize = mkOption {
        default = 64;
        type = types.nullOr types.int;
        description = ''
	   Set maximum icon size to px pixels.
        '';
      };

      iconPath = mkOption {
        default = null;
        type = types.nullOr types.str;
        description = ''
	   Paths to search for icons when a notification specifies a name instead of a full path. Colon-delimited. This approximates the search algorithm used by the XDG Icon Theme Specification, but does not support any of the theme metadata. Therefore, if you want to search parent themes, you'll need to add them to the path manually.

           /usr/share/icons/hicolor and /usr/share/pixmaps are always searched.
        '';
      };

      markup = mkOption {
        default = 1;
        type = types.nullOr types.bool;
        description = ''
	   If 1, enable Pango markup. If 0, disable Pango markup. If enabled, Pango markup will be interpreted in your format specifier and in the body of notifications.
        '';
      };

      actions = mkOption {
        default = 1;
        type = types.nullOr types.bool;
        description = ''
	   Applications may request an action to be associated with activating a notification. Disabling this will cause mako to ignore these requests.
        '';
      };

      format = mkOption {
        default = "<b>%s</b>\n%b";
        type = types.nullOr types.str;
        description = ''
	   Set notification format string to format. See FORMAT SPECIFIERS for more information. To change this for grouped notifications, set it within a grouped criteria.
        '';
      };

      defaultTimeout = mkOption {
        default = 0;
        type = types.nullOr types.bool;
        description = ''
	   Set the default timeout to timeout in milliseconds. To disable the timeout, set it to zero.
        '';
      };

      ignoreTimeout = mkOption {
        default = 0;
        type = types.nullOr types.bool;
        description = ''
	   If set, mako will ignore the expire timeout sent by notifications and use the one provided by default-timeout instead.
        '';
      };

      groupBy = mkOption {
        default = null;
        type = types.nullOr types.str;
        description = ''
	   A comma-separated list of criteria fields that will be compared to other visible notifications to determine if this one should form a group with them. All listed criteria must be exactly equal for two notifications to group.
        '';
      };

    };
  };

  config = (let
    boolToString = v: if v then "true" else "false";
    optionalBoolean = name: val:
      lib.optionalString (val != null) "${name} = ${boolToString val}";
    optionalInteger = name: val:
      lib.optionalString (val != null) "${name} = ${toString val}";
    optionalString = name: val:
      lib.optionalString (val != null) "${name} = ${val}";
  in mkIf cfg.enable {
    home.packages = [ pkgs.mako ];
    xdg.configFile."mako/config".text = ''
      [global]
      ${optionalInteger "max-visible" cfg.maxVisible}
      ${optionalString "sort" cfg.sort}
      ${optionalString "output" cfg.output}
      ${optionalString "layer" cfg.layer}
      ${optionalString "anchor" cfg.anchor}

      [style]
      ${optionalString "font" cfg.font}
      ${optionalString "background-color" cfg.backgroundColor}
      ${optionalString "text-color" cfg.textColor}
      ${optionalInteger "width" cfg.width}
      ${optionalInteger "height" cfg.height}
      ${optionalInteger "margin" cfg.margin}
      ${optionalInteger "padding" cfg.padding}
      ${optionalInteger "border-size" cfg.borderSize}
      ${optionalString "border-color" cfg.borderColor}
      ${optionalInteger "border-radius" cfg.borderRadius}
      ${optionalString "progress-color" cfg.progressColor}
      ${optionalBoolean "icons" cfg.icons}
      ${optionalInteger "max-icon-size" cfg.maxIconSize}
      ${optionalString "icon-path" cfg.iconPath}
      ${optionalBoolean "markup" cfg.markup}
      ${optionalBoolean "actions" cfg.actions}
      ${optionalString "format" cfg.format}
      ${optionalInteger "default-timeout" cfg.defaultTimeout}
      ${optionalBoolean "ignore-timeout" cfg.ignoreTimeout}
      ${optionalString "group-by" cfg.groupBy}
    '';

  });
}
