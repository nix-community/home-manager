{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.programs.contour;

  filteredKeybindings =
    map (keybind: filterAttrs (_: v: v != null) keybind) cfg.keybindings;
in {
  meta.maintainers = [ maintainers.ivan770 ];

  options.programs.contour = {
    enable = mkEnableOption "Contour terminal";

    package = mkOption {
      type = types.package;
      default = pkgs.contour;
      defaultText = literalExpression "pkgs.contour";
      description = ''
        Contour package to install
      '';
    };

    settings = mkOption {
      type = types.submodule {
        options = {
          platform_plugin = mkOption {
            type = types.enum [ "auto" "xcb" "cocoa" ];
            default = "auto";
            description = ''
              Overrides the auto-detected platform plugin to be loaded.
            '';
          };

          renderer = mkOption {
            type = types.submodule {
              options = {
                backend = mkOption {
                  type = types.enum [ "default" "software" "OpenGL" ];
                  default = "OpenGL";
                  description = ''
                    Backend to use for rendering the terminal onto the screen.
                  '';
                };

                tile_hashtable_slots = mkOption {
                  type = types.int;
                  default = 4096;
                  description = ''
                    Number of hashtable slots to map to the texture tiles.
                    Larger values may increase performance, but too large may also decrease.
                    This value is rounted up to a value equal to the power of two.
                  '';
                };

                tile_cache_count = mkOption {
                  type = types.int;
                  default = 4000;
                  description = ''
                    Number of tiles that must fit at lest into the texture atlas.

                    This does not include direct mapped tiles (US-ASCII glyphs,
                    cursor shapes and decorations), if tile_direct_mapping is set to true).

                    Value must be at least as large as grid cells available in the terminal view.
                    This value is automatically adjusted if too small.
                  '';
                };
              };
            };
            default = { };
            description = ''
              Terminal renderer configuration.
            '';
          };

          default_profile = mkOption {
            type = types.str;
            default = "main";
            description = ''
              Profile to use as a default one.
            '';
          };

          profiles = let
            mkCursorOption = attrs:
              mkOption {
                type = types.submodule {
                  options = {
                    shape = mkOption {
                      type =
                        types.enum [ "block" "rectangle" "underscore" "bar" ];
                      default = "bar";
                      description = ''
                        Terminal cursor shape.
                      '';
                    };

                    blinking = mkEnableOption "cursor blinking over time";

                    blinking_interval = mkOption {
                      type = types.int;
                      default = 500;
                      description = ''
                        Blinking interval (in milliseconds) to use when cursor is blinking.
                      '';
                    };
                  };
                };
                default = { };
              } // attrs;
          in mkOption {
            type = types.attrsOf (types.submodule {
              options = {
                shell = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                  description = ''
                    Process that will be started inside the terminal.

                    If null is specified, the users' default login shell will be used.
                  '';
                };

                arguments = mkOption {
                  type = types.nullOr (types.listOf types.str);
                  default = null;
                  description = ''
                    Arguments to pass to shell process.
                  '';
                };

                copy_last_mark_range_offset = mkOption {
                  type = types.int;
                  default = 0;
                  description = ''
                    Advanced value that is useful when CopyPreviousMarkRange is used
                    with multiline-prompts. This offset value is being added to the
                    current cursor's line number minus 1 (i.e. the line above the current cursor).
                  '';
                };

                initial_working_directory = mkOption {
                  type = types.str;
                  default = "~";
                  description = ''
                    Sets initial working directory when spawning a new terminal.
                    A leading ~ is expanded to the user's home directory.
                  '';
                };

                show_title_bar = mkEnableOption "window title bar" // {
                  default = true;
                };

                fullscreen = mkEnableOption "fullscreen mode";

                maximized = mkEnableOption "maximized mode";

                wm_class = mkOption {
                  type = types.str;
                  default = "contour";
                  description = ''
                    Defines the class part of the WM_CLASS property of the window.
                  '';
                };

                environment = mkOption {
                  type = types.nullOr (types.attrsOf types.str);
                  default = null;
                  example = ''
                    { TERM = "contour"; COLORTERM = "truecolor"; }
                  '';
                  description = ''
                    Environment variables to be passed to the shell.
                  '';
                };

                terminal_id = mkOption {
                  type = types.enum [
                    "VT100"
                    "VT220"
                    "VT240"
                    "VT330"
                    "VT340"
                    "VT320"
                    "VT420"
                    "VT510"
                    "VT520"
                    "VT525"
                  ];
                  default = "VT525";
                  description = ''
                    Determines the terminal type that is being advertised.
                  '';
                };

                terminal_size = mkOption {
                  type = types.submodule {
                    options = {
                      columns = mkOption {
                        type = types.int;
                        default = 80;
                        description = ''
                          Default terminal width in characters.
                        '';
                      };

                      lines = mkOption {
                        type = types.int;
                        default = 25;
                        description = ''
                          Default terminal height in characters.
                        '';
                      };
                    };
                  };
                  default = { };
                  description = ''
                    Determines the initial terminal size in characters.
                  '';
                };

                history = mkOption {
                  type = types.submodule {
                    options = {
                      limit = mkOption {
                        type = types.int;
                        default = 1000;
                        description = ''
                          Number of lines to preserve (-1 for infinite).
                        '';
                      };

                      auto_scroll_on_update = mkEnableOption
                        "scrolling down to bottom on screen updates" // {
                          default = true;
                        };

                      scroll_multiplier = mkOption {
                        type = types.int;
                        default = 3;
                        description = ''
                          Number of lines to scroll on ScrollUp and ScrollDown events.
                        '';
                      };
                    };
                  };
                  default = { };
                  description = ''
                    Terminal history configuration.
                  '';
                };

                scrollbar = mkOption {
                  type = types.submodule {
                    options = {
                      position = mkOption {
                        type = types.enum [ "left" "right" "hidden" ];
                        default = "right";
                        description = ''
                          Scrollbar position
                        '';
                      };

                      hide_in_alt_screen =
                        mkEnableOption "scrollbar hiding when in alt-screen"
                        // {
                          default = true;
                        };
                    };
                  };
                  default = { };
                };

                permissions = let
                  mkPermissionType = attrs:
                    mkOption {
                      type = types.enum [ "allow" "deny" "ask" ];
                      default = "ask";
                    } // attrs;
                in mkOption {
                  type = types.submodule {
                    options = {
                      change_font = mkPermissionType {
                        description =
                          "Allows changing the font via `OSC 50 ; Pt ST`.";
                      };

                      capture_buffer = mkPermissionType {
                        description = lib.mdDoc ''
                          Allows capturing the screen buffer via `CSI > Pm ; Ps ; Pc ST`.
                          The response can be read from stdin as sequence `OSC 314 ; <screen capture> ST`.
                        '';
                      };
                    };
                  };
                  default = { };
                  description = ''
                    VT sequence permissions.
                  '';
                };

                font = mkOption {
                  type = types.submodule {
                    options = {
                      size = mkOption {
                        type = types.int;
                        default = 12;
                        description = ''
                          Initial font size in pixels.
                        '';
                      };

                      dpi_scale = mkOption {
                        type = types.number;
                        default = 1.0;
                        description = ''
                          DPI scaling factor applied on top of the system configured on.
                        '';
                      };

                      locator = mkOption {
                        type = types.enum [ "native" "fontconfig" "CoreText" ];
                        default = "native";
                        description = ''
                          Font Locator API.

                          Selects an engine to use for locating font files on the system.
                          This is implicitly also responsible for font fallback.
                        '';
                      };

                      text_shaping = mkOption {
                        type = types.submodule {
                          options = {
                            engine = mkOption {
                              type =
                                types.enum [ "native" "CoreText" "OpenShaper" ];
                              default = "native";
                              description = ''
                                Selects which text shaping and font rendering engine to use.
                              '';
                            };
                          };
                        };
                        default = { };
                        description = ''
                          Text shaping related settings.
                        '';
                      };

                      builtin_box_drawing = mkEnableOption
                        "usage of built-in textures for pixel-perfect box drawing"
                        // {
                          default = true;
                        };

                      render_mode = mkOption {
                        type = types.enum [ "lcd" "light" "gray" "monochrome" ];
                        default = "gray";
                        description = ''
                          Font render modes tell the font rasterizer engine what rendering technique to use.
                        '';
                      };

                      strict_spacing = mkEnableOption
                        "usage of only monospace fonts in the font and font-fallback list"
                        // {
                          default = true;
                        };

                      regular = mkOption {
                        type = types.submodule {
                          options = {
                            family = mkOption {
                              type = types.str;
                              default = "monospace";
                              description = ''
                                Font family defines the font family name, such as:
                                "Fira Code", "Courier New", or "monospace".
                              '';
                            };

                            weight = mkOption {
                              type = types.enum [
                                "thin"
                                "extra_light"
                                "light"
                                "demilight"
                                "book"
                                "normal"
                                "medium"
                                "demibold"
                                "bold"
                                "extra_bold"
                                "black"
                                "extra_black"
                              ];
                              default = "normal";
                              description = ''
                                Font weight.
                              '';
                            };

                            slant = mkOption {
                              type = types.enum [ "normal" "italic" "oblique" ];
                              default = "normal";
                              description = ''
                                Font slant.
                              '';
                            };

                            features = mkOption {
                              type = types.listOf types.str;
                              default = [ ];
                              description = ''
                                Set of optional font features to be enabled. This
                                is usually a 4-letter code, such as ss01 or ss02 etc.

                                Please see your font's documentation to find out what it
                                supports.
                              '';
                            };
                          };
                        };
                        default = { };
                        description = ''
                          Font family to use for displaying text.
                        '';
                      };

                      bold = mkOption {
                        type = types.nullOr types.str;
                        default = null;
                        example = "Hack";
                        description = ''
                          Font to be used for bold text.
                        '';
                      };

                      italic = mkOption {
                        type = types.nullOr types.str;
                        default = null;
                        example = "Hack";
                        description = ''
                          Font to be used for italic text.
                        '';
                      };

                      bold_italic = mkOption {
                        type = types.nullOr types.str;
                        default = null;
                        example = "Hack";
                        description = ''
                          Font to be used for bold italic text.
                        '';
                      };

                      emoji = mkOption {
                        type = types.str;
                        default = "emoji";
                        description = ''
                          This is a special font to be used for displaying unicode symbols
                          that are to be rendered in emoji presentation.
                        '';
                      };
                    };
                  };
                  default = { };
                  description = ''
                    Font related configuration (font face, styles, size, rendering mode).
                  '';
                };

                bold_is_bright = mkEnableOption "bright bold text";

                cursor = mkCursorOption {
                  description = ''
                    Terminal cursor display configuration.
                  '';
                };

                normal_mode = mkOption {
                  type = types.submodule {
                    options = {
                      cursor = mkCursorOption {
                        description = ''
                          Terminal cursor configuration for normal mode.
                        '';
                      };
                    };
                  };
                  default = { };
                  description = ''
                    vi-like normal-mode specific settings.
                  '';
                };

                visual_mode = mkOption {
                  type = types.submodule {
                    options = {
                      cursor = mkCursorOption {
                        description = ''
                          Terminal cursor configuration for visual mode.
                        '';
                      };
                    };
                  };
                  default = { };
                  description = ''
                    vi-like visual/visual-line/visual-block mode specific settings.
                  '';
                };

                background = mkOption {
                  type = types.submodule {
                    options = {
                      opacity = mkOption {
                        type = types.numbers.between 0.0 1.0;
                        default = 1.0;
                        description = ''
                          Background opacity to use. A value of 1.0 means fully opaque whereas 0.0 means fully
                          transparent. Only values between 0.0 and 1.0 are allowed.
                        '';
                      };

                      # Blur is not supported at the moment.
                    };
                  };
                  default = { };
                  description = ''
                    Background configuration.
                  '';
                };

                colors = mkOption {
                  type = types.str;
                  default = "default";
                  description = ''
                    Specifies a colorscheme to use.
                  '';
                };

                draw_bold_text_with_bright_colors =
                  mkEnableOption "usage of bright colors on bold text";

                hyperlink_decoration = let
                  supportedDecorations = types.enum [ "dotted" "underline" ];
                in mkOption {
                  type = types.submodule {
                    options = {
                      normal = mkOption {
                        type = supportedDecorations;
                        default = "dotted";
                        description = ''
                          Default hyperlink decorations.
                        '';
                      };

                      hover = mkOption {
                        type = supportedDecorations;
                        default = "underline";
                        description = ''
                          Hovered hyperlink decorations.
                        '';
                      };
                    };
                  };
                  default = { };
                  description = ''
                    OSC-8 hyperlinks decorations configuration.
                  '';
                };
              };
            });
            default = { main = { }; };
            description = ''
              Dominates how your terminal visually looks like. You will need at least one terminal profile.
            '';
          };

          color_schemes = let
            mkColorOption = attrs:
              mkOption {
                type = types.str;
                example = "#1d1f21";
              } // attrs;
          in mkOption {
            type = types.attrsOf (types.submodule {
              options = {
                default = mkOption {
                  type = types.submodule {
                    options = {
                      background = mkColorOption {
                        default = "#1d1f21";
                        description = ''
                          Default background color.
                        '';
                      };

                      foreground = mkColorOption {
                        default = "#d5d8d6";
                        description = ''
                          Default foreground text color.
                        '';
                      };
                    };
                  };
                  default = { };
                  description = ''
                    Default terminal colors.
                  '';
                };

                background_image = mkOption {
                  type = types.submodule {
                    options = {
                      path = mkOption {
                        type = types.nullOr types.str;
                        default = null;
                        example = "/home/user/Pictures/bg.png";
                        description = ''
                          Full path to the image to use as background.
                        '';
                      };

                      opacity = mkOption {
                        type = types.number;
                        default = 0.5;
                        description = ''
                          Image opacity to be applied to make the image not look to intense
                          and not get too distracted by the background image.
                        '';
                      };

                      blur = mkEnableOption "background image blur";
                    };
                  };
                  default = { };
                  description = ''
                    Background image configuration.
                  '';
                };

                cursor = mkOption {
                  type = types.submodule {
                    options = {
                      default = mkColorOption {
                        default = "CellForeground";
                        description = ''
                          Specifies the color to be used for the actual cursor shape.
                        '';
                      };

                      text = mkColorOption {
                        default = "CellBackground";
                        description = ''
                          Specifies the color to be used for the characters that would be covered otherwise.
                        '';
                      };
                    };
                  };
                  default = { };
                  description = ''
                    Mandates the color of the cursor and potentially overridden text.

                    The color can be specified in RGB as usual, plus CellForeground, which
                    selects the cell's foreground color, and CellBackground, which selects the cell's background color.
                  '';
                };

                hyperlink_decoration = mkOption {
                  type = types.submodule {
                    options = {
                      normal = mkColorOption {
                        default = "#f0f000";
                        description = "Hyperlink color without hovering";
                      };

                      hover = mkColorOption {
                        default = "#ff0000";
                        description = "Hyperlink color when hovering";
                      };
                    };
                  };
                  default = { };
                  description = ''
                    Hyperlinks decorations color configuration.
                  '';
                };

                selection = mkOption {
                  type = types.nullOr (types.submodule {
                    options = {
                      foreground = mkColorOption {
                        default = "#c0c0c0";
                        description = "Selection foreground color";
                      };

                      background = mkColorOption {
                        default = "#a000a0";
                        description = "Selection background color";
                      };
                    };
                  });
                  default = null;
                  description = ''
                    The text selection color configuration.
                    Leaving a null value will default to the inverse of the content's color values.
                  '';
                };

                normal = mkOption {
                  type = types.submodule {
                    options = {
                      black = mkColorOption {
                        default = "#1d1f21";
                        description = "Black color value";
                      };

                      red = mkColorOption {
                        default = "#cc342b";
                        description = "Red color value";
                      };

                      green = mkColorOption {
                        default = "#198844";
                        description = "Green color value";
                      };

                      yellow = mkColorOption {
                        default = "#fba922";
                        description = "Yellow color value";
                      };

                      blue = mkColorOption {
                        default = "#3971ed";
                        description = "Blue color value";
                      };

                      magenta = mkColorOption {
                        default = "#a36ac7";
                        description = "Magenta color value";
                      };

                      cyan = mkColorOption {
                        default = "#3971ed";
                        description = "Cyan color value";
                      };

                      white = mkColorOption {
                        default = "#c5c8c6";
                        description = "White color value";
                      };
                    };
                  };
                  default = { };
                  description = ''
                    Normal text color configuration.
                  '';
                };

                dim = mkOption {
                  type = types.nullOr (types.submodule {
                    options = {
                      black = mkColorOption {
                        default = "#1d1f21";
                        description = "Black color value";
                      };

                      red = mkColorOption {
                        default = "#cc342b";
                        description = "Red color value";
                      };

                      green = mkColorOption {
                        default = "#198844";
                        description = "Green color value";
                      };

                      yellow = mkColorOption {
                        default = "#fba922";
                        description = "Yellow color value";
                      };

                      blue = mkColorOption {
                        default = "#3971ed";
                        description = "Blue color value";
                      };

                      magenta = mkColorOption {
                        default = "#a36ac7";
                        description = "Magenta color value";
                      };

                      cyan = mkColorOption {
                        default = "#3971ed";
                        description = "Cyan color value";
                      };

                      white = mkColorOption {
                        default = "#c5c8c6";
                        description = "White color value";
                      };
                    };
                  });
                  default = { };
                  description = ''
                    Dim (faint) text color configuration.

                    When value is null, colors are automatically computed based on normal colors
                  '';
                };

                bright = mkOption {
                  type = types.submodule {
                    options = {
                      black = mkColorOption {
                        default = "#969896";
                        description = "Black color value";
                      };

                      red = mkColorOption {
                        default = "#cc342b";
                        description = "Red color value";
                      };

                      green = mkColorOption {
                        default = "#198844";
                        description = "Green color value";
                      };

                      yellow = mkColorOption {
                        default = "#fba922";
                        description = "Yellow color value";
                      };

                      blue = mkColorOption {
                        default = "#3971ed";
                        description = "Blue color value";
                      };

                      magenta = mkColorOption {
                        default = "#a36ac7";
                        description = "Magenta color value";
                      };

                      cyan = mkColorOption {
                        default = "#3971ed";
                        description = "Cyan color value";
                      };

                      white = mkColorOption {
                        default = "#ffffff";
                        description = "White color value";
                      };
                    };
                  };
                  default = { };
                  description = ''
                    Bright text color configuration.
                  '';
                };
              };
            });
            default = { default = { }; };
            description = ''
              Color profiles configuration.
            '';
          };
        };
      };
      default = { };
      description = ''
        General Contour configuration.
      '';
    };

    keybindings = mkOption {
      type = types.listOf (types.submodule {
        options = {
          mods = mkOption {
            type = types.listOf (types.enum [ "Alt" "Control" "Shift" "Meta" ]);
            default = [ ];
            example = ''
              ["Control" "Alt"]
            '';
            description = ''
              Modifier keys.
            '';
          };

          key = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = ''
              Space
            '';
            description = ''
              Keys can be expressed case-insensitively symbolic:

              APOSTROPHE, ADD, BACKSLASH, COMMA, DECIMAL, DIVIDE, EQUAL, LEFT_BRACKET,
              MINUS, MULTIPLY, PERIOD, RIGHT_BRACKET, SEMICOLON, SLASH, SUBTRACT, SPACE
              Enter, Backspace, Tab, Escape, F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12,
              DownArrow, LeftArrow, RightArrow, UpArrow, Insert, Delete, Home, End, PageUp, PageDown,
              Numpad_NumLock, Numpad_Divide, Numpad_Multiply, Numpad_Subtract, Numpad_CapsLock,
              Numpad_Add, Numpad_Decimal, Numpad_Enter, Numpad_Equal,
              Numpad_0, Numpad_1, Numpad_2, Numpad_3, Numpad_4,
              Numpad_5, Numpad_6, Numpad_7, Numpad_8, Numpad_9.

              In case of standard characters, just the character.
            '';
          };

          mouse = mkOption {
            type = types.nullOr
              (types.enum [ "Left" "Middle" "Right" "WheelUp" "WheelDown" ]);
            default = null;
            description = ''
              Mouse button specification.
            '';
          };

          action = mkOption {
            type = types.enum [
              "CancelSelection"
              "ChangeProfile"
              "ClearHistoryAndReset"
              "CopyPreviousMarkRange"
              "CopySelection"
              "DecreaseFontSize"
              "DecreaseOpacity"
              "FollowHyperlink"
              "IncreaseFontSize"
              "IncreaseOpacity"
              "NewTerminal"
              "OpenConfiguration"
              "OpenFileManager"
              "PasteClipboard"
              "PasteSelection"
              "Quit"
              "ReloadConfig"
              "ResetConfig"
              "ResetFontSize"
              "ScreenshotVT"
              "ScrollDown"
              "ScrollMarkDown"
              "ScrollMarkUp"
              "ScrollOneDown"
              "ScrollOneUp"
              "ScrollPageDown"
              "ScrollPageUp"
              "ScrollToBottom"
              "ScrollToTop"
              "ScrollUp"
              "SendChars"
              "ToggleAllKeyMaps"
              "ToggleFullScreen"
              "ToggleTitleBar"
              "ViNormalMode"
              "WriteScreen"
            ];
            description = ''
              Action to be executed on mapped input activation.
            '';
          };

          mode = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = lib.mdDoc ''
              Additionally one can filter input mappings based on special terminal modes using the `modes` option:

              * Alt       : The terminal is currently in alternate screen buffer, otherwise it is in primary screen buffer.
              * AppCursor : The application key cursor mode is enabled (otherwise it's normal cursor mode).
              * AppKeypad : The application keypad mode is enabled (otherwise it's the numeric keypad mode).
              * Select    : The terminal has currently an active grid cell selection (such as selected text).
              * Insert    : The Insert input mode is active, that is the default and one way to test that the input mode is not in normal mode or any of the visual select modes.

              You can combine these modes by concatenating them via | and negate a single one
              by prefixing with ~.
            '';
          };
        };
      });
      default = [
        {
          mods = [ "Control" ];
          mouse = "Left";
          action = "FollowHyperlink";
        }
        {
          mouse = "Middle";
          action = "PasteSelection";
        }
        {
          mouse = "WheelDown";
          action = "ScrollDown";
        }
        {
          mouse = "WheelUp";
          action = "ScrollUp";
        }
        {
          mods = [ "Alt" ];
          key = "Enter";
          action = "ToggleFullScreen";
        }
        {
          mods = [ "Alt" ];
          mouse = "WheelDown";
          action = "DecreaseOpacity";
        }
        {
          mods = [ "Alt" ];
          mouse = "WheelUp";
          action = "IncreaseOpacity";
        }
        {
          mods = [ "Control" "Alt" ];
          key = "S";
          action = "ScreenshotVT";
        }
        {
          mods = [ "Control" "Shift" ];
          key = "Plus";
          action = "IncreaseFontSize";
        }
        {
          mods = [ "Control" ];
          key = "0";
          action = "ResetFontSize";
        }
        {
          mods = [ "Control" "Shift" ];
          key = "Minus";
          action = "DecreaseFontSize";
        }
        {
          mods = [ "Control" "Shift" ];
          key = "_";
          action = "DecreaseFontSize";
        }
        {
          mods = [ "Control" "Shift" ];
          key = "N";
          action = "NewTerminal";
        }
        {
          mods = [ "Control" "Shift" ];
          key = "C";
          action = "CopySelection";
        }
        {
          mods = [ "Control" "Shift" ];
          key = "V";
          action = "PasteClipboard";
        }
        {
          mods = [ "Control" ];
          key = "C";
          action = "CopySelection";
          mode = "Select|Insert";
        }
        {
          mods = [ "Control" ];
          key = "V";
          action = "PasteClipboard";
          mode = "Select|Insert";
        }
        {
          mods = [ "Control" ];
          key = "V";
          action = "CancelSelection";
          mode = "Select|Insert";
        }
        {
          key = "Escape";
          action = "CancelSelection";
          mode = "Select|Insert";
        }
        {
          mods = [ "Control" "Shift" ];
          key = "Space";
          action = "ViNormalMode";
          mode = "Insert";
        }
        {
          mods = [ "Control" "Shift" ];
          key = "Comma";
          action = "OpenConfiguration";
        }
        {
          mods = [ "Control" "Shift" ];
          key = "Q";
          action = "Quit";
        }
        {
          mods = [ "Control" ];
          mouse = "WheelDown";
          action = "DecreaseFontSize";
        }
        {
          mods = [ "Control" ];
          mouse = "WheelUp";
          action = "IncreaseFontSize";
        }
        {
          mods = [ "Shift" ];
          key = "DownArrow";
          action = "ScrollOneDown";
        }
        {
          mods = [ "Shift" ];
          key = "End";
          action = "ScrollToBottom";
        }
        {
          mods = [ "Shift" ];
          key = "Home";
          action = "ScrollToTop";
        }
        {
          mods = [ "Shift" ];
          key = "PageDown";
          action = "ScrollPageDown";
        }
        {
          mods = [ "Shift" ];
          key = "PageUp";
          action = "ScrollPageUp";
        }
        {
          mods = [ "Shift" ];
          key = "UpArrow";
          action = "ScrollOneUp";
        }
        {
          mods = [ "Shift" ];
          key = "{";
          action = "ScrollMarkUp";
          mode = "~Alt";
        }
        {
          mods = [ "Shift" ];
          key = "}";
          action = "ScrollMarkDown";
          mode = "~Alt";
        }
        {
          mods = [ "Shift" ];
          mouse = "WheelDown";
          action = "ScrollPageDown";
        }
        {
          mods = [ "Shift" ];
          mouse = "WheelUp";
          action = "ScrollPageUp";
        }
        {
          mods = [ "Control" ];
          key = "O";
          action = "OpenFileManager";
        }
      ];
      description = ''
        Keybindings configuration.
      '';
    };

    extraConfig = mkOption {
      type = types.attrs;
      default = { };
      description = ''
        Extra configuration that overrides primary settings.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."contour/contour.yml" = {
      text = lib.generators.toYAML { } (filterAttrsRecursive (_: v: v != null)
        (cfg.settings // { input_mapping = filteredKeybindings; })
        // cfg.extraConfig);
    } // optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      onChange = ''
        ${pkgs.procps}/bin/pkill -USR1 -u $USER contour || true
      '';
    };
  };
}
