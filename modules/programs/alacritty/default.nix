{ config, lib, pkgs, ... }:

with lib;

let
  defaults = import ./default-config.nix;
  cfg = config.programs.alacritty;

  mapAttrNamesRecursive' = f: set:
    let
      recurse = set:
        let
          g =
            name: value:
            if isAttrs value
              then nameValuePair (f name) (recurse value)
              else nameValuePair (f name) value;
        in mapAttrs' g set;
    in recurse set;

  toSnakeCase = replaceChars upperChars (map (c: "_${c}") lowerChars);

  animationList = [
    "Ease"
    "EaseOut"
    "EaseOutSine"
    "EaseOutQuad"
    "EaseOutCubic"
    "EaseOutQuart"
    "EaseOutQuint"
    "EaseOutExpo"
    "EaseOutCirc"
    "Linear"
  ];
  actionList = [
    "Paste"
    "PasteSelection"
    "Copy"
    "IncreaseFontSize"
    "DecreaseFontSize"
    "ResetFontSize"
    "ScrollPageUp"
    "ScrollPageDown"
    "ScrollToTop"
    "ScrollToBottom"
    "ClearHistory"
    "Hide"
    "Quit"
    "ClearLogNotice"
  ];
  modList = [
    "Command"
    "Control"
    "Shift"
    "Alt"
  ];
  modeList = [
    "~AppCursor"
    "AppCursor"
    "~AppKeypad"
    "AppKeypad"
  ];
in {
  options.programs.alacritty = with types; {
    enable = mkEnableOption "Alacritty terminal";
    window = {
      dimensions = {
        columns = mkOption {
          type = int;
          default = 80;
          description = "Number of columns in the window";
        };
        lines = mkOption {
          type = int;
          default = 24;
          description = "Number of lines in the window";
        };
      };
      padding = {
        x = mkOption {
          type = int;
          default = 2;
          description = "Horizontal padding around the window, in pixels";
        };
        y = mkOption {
          type = int;
          default = 2;
          description = "Vertical padding around the window, in pixels";
        };
      };
      decorations = mkOption {
        description = ''
          Window decorations
            - full: Borders and title bar
            - none: Neither borders nor title bar
        '';
        type = enum [ "none" "full" ];
        default = "full";
      };
    };
    scrolling = {
      history = mkOption {
        type = int;
        description = ''
          Maximum number of lines in the scrollback buffer.
          Specifying '0' will disable scrolling.
        '';
        default = 10000;
      };
      multiplier = mkOption {
        type = int;
        description = "Number of lines the viewport will move for every line scrolled.";
        default = 3;
      };
      autoScroll = mkOption {
        type = bool;
        description = "Scroll to the bottom when new text is written to the terminal.";
        default = false;
      };
    };
    font = let
      fontOption = {
        family = mkOption {
          type = string;
          description = "Font family to use.";
          default = "monospace";
        };
        style = mkOption {
          type = nullOr (enum ["Regular" "Bold" "Italic"]);
          default = null;
          description = "Font style to use.";
        };
      };
    in {
      normal = fontOption;
      bold = fontOption;
      italic = fontOption;
      size = mkOption {
        type = float;
        description = "Point size.";
        default = 11;
      };
      offset = {
        x = mkOption {
          default = 0;
          type = int;
          description = "Letter spacing.";
        };
        y = mkOption {
          default = 0;
          type = int;
          description = "Line spacing.";
        };
      };
      glyphOffset = {
        x = mkOption {
          default = 0;
          type = int;
          description = "Glyph offset determines the locations of the glyphs within their cells with the default being at the bottom. Increasing x moves it towards the right.";
        };
        y = mkOption {
          default = 0;
          type = int;
          description = "Glyph offset determines the locations of the glyphs within their cells with the default being at the bottom. Increasing y moves it to upwards.";
        };
      };
    };
    drawBoldTextWithBrightColors = mkOption {
      type = bool;
      default = true;
      description = "If true, bold text is drawn using the bright color variants.";
    };
    colors = {
      primary = {
        background = mkOption {
          type = string;
          default = "0x000000";
          description = "Background color";
          example = literalExample "0x000000";
        };
        foreground = mkOption {
          type = string;
          default = "0xeaeaea";
          description = "Foreground color";
          example = literalExample "0xeaeaea";
        };
      };
    };
    backgroundOpacity = mkOption {
      type = float;
      default = 1.0;
      description = ''
        Window opacity as a floating point number from 0.0 to 1.0.
        The value 0.0 is completely transparent and 1.0 is opaque.
      '';
    };
    cursor = {
      style = mkOption {
        type = enum [ "Block" "Underline" "Beam" ];
        default = "Block";
        description = "The cursor style.";
        example = literalExample "Underline";
      };
      unfocusedHollow = mkOption {
        type = bool;
        default = true;
        description = "If this is true, the cursor will be rendered as a hollow box when the window is not focused.";
      };
    };
    extraConfig = mkOption {
      type = attrs;
      default = {};
      description = "Any extra options. These will be merged into the other options set.";
      example = literalExample ''
      {
        keyBindings = [
          { key = "V"; mods = "Control|Shift"; action = "Paste"; }
          { key = "C"; mods = "Control|Shift"; action = "Copy"; }
        ];
      }
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.alacritty ];

    xdg.configFile."alacritty/alacritty.yml".text = let
        tmp = filterAttrsRecursive (n: v: v != null && v != "" && v != [] && n != "extraConfig") cfg;
        merged = recursiveUpdate tmp cfg.extraConfig;
        set = mapAttrNamesRecursive' toSnakeCase merged;
      in replaceStrings ["\\\\u"] ["\\u"] (builtins.toJSON (recursiveUpdate defaults set));
  };
}
