{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.kakoune;

  hook = types.submodule {
    options = {
      name = mkOption {
        type = types.enum [
          "NormalBegin" "NormalIdle" "NormalEnd" "NormalKey"
          "InsertBegin" "InsertIdle" "InsertEnd" "InsertKey"
          "InsertChar" "InsertDelete" "InsertMove" "WinCreate"
          "WinClose" "WinResize" "WinDisplay" "WinSetOption"
          "BufSetOption" "BufNewFile" "BufOpenFile" "BufCreate"
          "BufWritePre" "BufWritePost" "BufReload" "BufClose"
          "BufOpenFifo" "BufReadFifo" "BufCloseFifo" "RuntimeError"
          "ModeChange" "PromptIdle" "GlobalSetOption" "KakBegin"
          "KakEnd" "FocusIn" "FocusOut" "RawKey"
          "InsertCompletionShow" "InsertCompletionHide"
          "InsertCompletionSelect"
        ];
        example = "SetOption";
        description = ''
          The name of the hook. For a description, see
          <link xlink:href="https://github.com/mawww/kakoune/blob/master/doc/pages/hooks.asciidoc#default-hooks"/>.
        '';
      };

      once = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Remove the hook after running it once.
        '';
      };

      group = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Add the hook to the named group.
        '';
      };

      option = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "filetype=latex";
        description = ''
          Additional option to pass to the hook.
        '';
      };

      commands = mkOption {
        type = types.lines;
        default = "";
        example = "set-option window indentwidth 2";
        description = ''
          Commands to run when the hook is activated.
        '';
      };
    };
  };

  keyMapping = types.submodule {
    options = {
      mode = mkOption {
        type = types.enum [
          "insert"
          "normal"
          "prompt"
          "menu"
          "user"
          "goto"
          "view"
          "object"
        ];
        example = "user";
        description = ''
          The mode in which the mapping takes effect.
        '';
      };

      docstring = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Optional documentation text to display in info boxes.
        '';
      };

      key = mkOption {
        type = types.str;
        example = "<a-x>";
        description = ''
          The key to be mapped. See
          <link xlink:href="https://github.com/mawww/kakoune/blob/master/doc/pages/mapping.asciidoc#mappable-keys"/>
          for possible values.
        '';
      };

      effect = mkOption {
        type = types.str;
        example = ":wq<ret>";
        description = ''
          The sequence of keys to be mapped.
        '';
      };
    };
  };

  configModule = types.submodule {
    options = {
      colorScheme = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Set the color scheme. To see available schemes, enter
          <command>colorscheme</command> at the kakoune prompt.
        '';
      };

      tabStop = mkOption {
        type = types.nullOr types.ints.unsigned;
        default = null;
        description = ''
          The width of a tab in spaces. The kakoune default is
          <literal>6</literal>.
        '';
      };

      indentWidth = mkOption {
        type = types.nullOr types.ints.unsigned;
        default = null;
        description = ''
          The width of an indentation in spaces.
          The kakoune default is <literal>4</literal>.
          If <literal>0</literal>, a tab will be used instead.
        '';
      };

      incrementalSearch = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Execute a search as it is being typed.
        '';
      };

      alignWithTabs = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Use tabs for the align command.
        '';
      };

      autoInfo = mkOption {
        type = types.nullOr (types.listOf (types.enum [ "command" "onkey" "normal" ]));
        default = null;
        example = [ "command" "normal" ];
        description = ''
          Contexts in which to display automatic information box.
          The kakoune default is <literal>[ "command" "onkey" ]</literal>.
        '';
      };

      autoComplete = mkOption {
        type = types.nullOr(types.listOf (types.enum [ "insert" "prompt" ]));
        default = null;
        description = ''
          Modes in which to display possible completions.
          The kakoune default is <literal>[ "insert" "prompt" ]</literal>.
        '';
      };

      autoReload = mkOption {
        type = types.nullOr (types.enum [ "yes" "no" "ask" ]);
        default = null;
        description = ''
          Reload buffers when an external modification is detected.
          The kakoune default is <literal>"ask"</literal>.
        '';
      };

      scrollOff = mkOption {
        type = types.nullOr (types.submodule {
          options = {
            lines = mkOption {
              type = types.ints.unsigned;
              default = 0;
              description = ''
                The number of lines to keep visible around the cursor.
              '';
            };

            columns = mkOption {
              type = types.ints.unsigned;
              default = 0;
              description = ''
                The number of columns to keep visible around the cursor.
              '';
            };
          };
        });
        default = null;
        description = ''
          How many lines and columns to keep visible around the cursor.
        '';
      };

      ui = mkOption {
        type = types.nullOr (types.submodule {
          options = {
            setTitle = mkOption {
              type = types.bool;
              default = false;
              description = ''
                Change the title of the terminal emulator.
              '';
            };

            statusLine = mkOption {
              type = types.enum [ "top" "bottom" ];
              default = "bottom";
              description = ''
                Where to display the status line.
              '';
            };

            assistant = mkOption {
              type = types.enum [ "clippy" "cat" "dilbert" "none" ];
              default = "clippy";
              description = ''
                The assistant displayed in info boxes.
              '';
            };

            enableMouse = mkOption {
              type = types.bool;
              default = false;
              description = ''
                Whether to enable mouse support.
              '';
            };

            changeColors = mkOption {
              type = types.bool;
              default = true;
              description = ''
                Change color palette.
              '';
            };

            wheelDownButton = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                Button to send for wheel down events.
              '';
            };

            wheelUpButton = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                Button to send for wheel up events.
              '';
            };

            shiftFunctionKeys = mkOption {
              type = types.nullOr types.ints.unsigned;
              default = null;
              description = ''
                Amount by which shifted function keys are offset. That
                is, if the terminal sends F13 for Shift-F1, this
                should be <literal>12</literal>.
              '';
            };

            useBuiltinKeyParser = mkOption {
              type = types.bool;
              default = false;
              description = ''
                Bypass ncurses key parser and use an internal one.
              '';
            };
          };
        });
        default = null;
        description = ''
          Settings for the ncurses interface.
        '';
      };

      showMatching = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Highlight the matching char of the character under the
          selections' cursor using the <literal>MatchingChar</literal>
          face.
        '';
      };

      wrapLines = mkOption {
        type = types.nullOr (types.submodule {
          options = {
            enable = mkEnableOption "the wrap lines highlighter";

            word = mkOption {
              type = types.bool;
              default = false;
              description = ''
                Wrap at word boundaries instead of codepoint boundaries.
              '';
            };

            indent = mkOption {
              type = types.bool;
              default = false;
              description = ''
                Preserve line indentation when wrapping.
              '';
            };

            maxWidth = mkOption {
              type = types.nullOr types.ints.unsigned;
              default = null;
              description = ''
                Wrap text at maxWidth, even if the window is wider.
              '';
            };

            marker = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "⏎";
              description = ''
                Prefix wrapped lines with marker text.
                If not <literal>null</literal>,
                the marker text will be displayed in the indentation if possible.
              '';
            };
          };
        });
        default = null;
        description = ''
          Settings for the wrap lines highlighter.
        '';
      };

      numberLines = mkOption {
        type = types.nullOr (types.submodule {
          options = {
            enable = mkEnableOption "the number lines highlighter";

            relative = mkOption {
              type = types.bool;
              default = false;
              description = ''
                Show line numbers relative to the main cursor line.
              '';
            };

            highlightCursor = mkOption {
              type = types.bool;
              default = false;
              description = ''
                Highlight the cursor line with a separate face.
              '';
            };

            separator = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                String that separates the line number column from the
                buffer contents. The kakoune default is
                <literal>"|"</literal>.
              '';
            };
          };
        });
        default = null;
        description = ''
          Settings for the number lines highlighter.
        '';
      };

      showWhitespace = mkOption {
        type = types.nullOr (types.submodule {
          options = {
            enable = mkEnableOption "the show whitespace highlighter";

            lineFeed = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                The character to display for line feeds.
                The kakoune default is <literal>"¬"</literal>.
              '';
            };

            space = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                The character to display for spaces.
                The kakoune default is <literal>"·"</literal>.
              '';
            };

            nonBreakingSpace = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                The character to display for non-breaking spaces.
                The kakoune default is <literal>"⍽"</literal>.
              '';
            };

            tab = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                The character to display for tabs.
                The kakoune default is <literal>"→"</literal>.
              '';
            };

            tabStop = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                The character to append to tabs to reach the width of a tabstop.
                The kakoune default is <literal>" "</literal>.
              '';
            };
          };
        });
        default = null;
        description = ''
          Settings for the show whitespaces highlighter.
        '';
      };

      keyMappings = mkOption {
        type = types.listOf keyMapping;
        default = [];
        description = ''
          User-defined key mappings. For documentation, see
          <link xlink:href="https://github.com/mawww/kakoune/blob/master/doc/pages/mapping.asciidoc"/>.
        '';
      };

      hooks = mkOption {
        type = types.listOf hook;
        default = [];
        description = ''
          Global hooks. For documentation, see
          <link xlink:href="https://github.com/mawww/kakoune/blob/master/doc/pages/hooks.asciidoc"/>.
        '';
      };
    };
  };

  configFile =
    let
      wrapOptions = with cfg.config.wrapLines; concatStrings [
        "${optionalString word " -word"}"
        "${optionalString indent " -indent"}"
        "${optionalString (marker != null) " -marker ${marker}"}"
        "${optionalString (maxWidth != null) " -width ${toString maxWidth}"}"
      ];

      numberLinesOptions = with cfg.config.numberLines; concatStrings [
        "${optionalString relative " -relative "}"
        "${optionalString highlightCursor " -hlcursor"}"
        "${optionalString (separator != null) " -separator ${separator}"}"
      ];

      uiOptions = with cfg.config.ui; concatStringsSep " " [
        "ncurses_set_title=${if setTitle then "true" else "false"}"
        "ncurses_status_on_top=${if (statusLine == "top") then "true" else "false"}"
        "ncurses_assistant=${assistant}"
        "ncurses_enable_mouse=${if enableMouse then "true" else "false"}"
        "ncurses_change_colors=${if changeColors then "true" else "false"}"
        "${optionalString (wheelDownButton != null)
          "ncurses_wheel_down_button=${wheelDownButton}"}"
        "${optionalString (wheelUpButton != null)
          "ncurses_wheel_up_button=${wheelUpButton}"}"
        "${optionalString (shiftFunctionKeys != null)
          "ncurses_shift_function_key=${toString shiftFunctionKeys}"}"
        "ncurses_builtin_key_parser=${if useBuiltinKeyParser then "true" else "false"}"
      ];

      keyMappingString = km: concatStringsSep " " [
        "map global"
        "${km.mode} ${km.key} '${km.effect}'"
        "${optionalString (km.docstring != null) "-docstring '${km.docstring}'"}"
      ];

      hookString = h: concatStringsSep " " [
        "hook" "${optionalString (h.group != null) "-group ${group}"}"
        "${optionalString (h.once) "-once"}" "global"
        "${h.name}" "${optionalString (h.option != null) h.option}"
        "%{ ${h.commands} }"
      ];

      cfgStr = with cfg.config; concatStringsSep "\n" (
        [ "# Generated by home-manager" ]
        ++ optional (colorScheme != null) "colorscheme ${colorScheme}"
        ++ optional (tabStop != null) "set-option global tabstop ${toString tabStop}"
        ++ optional (indentWidth != null) "set-option global indentwidth ${toString indentWidth}"
        ++ optional (!incrementalSearch) "set-option global incsearch false"
        ++ optional (alignWithTabs) "set-option global aligntab true"
        ++ optional (autoInfo != null) "set-option global autoinfo ${concatStringsSep "|" autoInfo}"
        ++ optional (autoComplete != null) "set-option global autocomplete ${concatStringsSep "|" autoComplete}"
        ++ optional (autoReload != null) "set-option global/ autoreload ${autoReload}"
        ++ optional (wrapLines != null && wrapLines.enable) "add-highlighter global/ wrap${wrapOptions}"
        ++ optional (numberLines != null && numberLines.enable)
          "add-highlighter global/ number-lines${numberLinesOptions}"
        ++ optional showMatching "add-highlighter global/ show-matching"
        ++ optional (scrollOff != null)
          "set-option global scrolloff ${toString scrollOff.lines},${toString scrollOff.columns}"

        ++ [ "# UI options" ]
        ++ optional (ui != null) "set-option global ui_options ${uiOptions}"

        ++ [ "# Key mappings" ]
        ++ map keyMappingString keyMappings

        ++ [ "# Hooks" ]
        ++ map hookString hooks
      );
    in
      pkgs.writeText "kakrc" (
        optionalString (cfg.config != null) cfgStr
        + cfg.extraConfig
      );

in

{
  options = {
    programs.kakoune = {
      enable = mkEnableOption "the kakoune text editor";

      config = mkOption {
        type = types.nullOr configModule;
        default = {};
        description = "kakoune configuration options.";
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Extra configuration lines to add to
          <filename>~/.config/kak/kakrc</filename>.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.kakoune ];
    xdg.configFile."kak/kakrc".source = configFile;
  };
}
