{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.kakoune;

  configModule = types.submodule {
    options = {

      tabStop = mkOption {
        type = types.nullOr types.ints.unsigned;
        default = null;
        description = ''
          The width of a tab.
        '';
      };

      indentWidth = mkOption {
        type = types.nullOr types.ints.unsigned;
        default = null;
        description = ''
          Width of an indentation in spaces.
          If this is 0, a tab will be used instead.
        '';
      };

      incrementalSearch = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to execute a search as it is being typed.
        '';
      };

      alignWithTabs = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to use tabs for the align command.
        '';
      };

      autoInfo = mkOption {
        type = types.nullOr (types.listOf (types.enum [ "command" "onkey" "normal" ]));
        default = null;
        description = ''
          Contexts in which to display automatic information box.
        '';
      };

      autoComplete = mkOption {
        type = types.nullOr(types.listOf (types.enum [  "insert" "prompt" ]));
        default = null;
        description = ''
          Modes in which to display possible completions.
        '';
      };

      autoReload = mkOption {
        type = types.nullOr (types.enum [ "yes" "no" "ask" ]);
        default = null;
        description = ''
          Whether to reload buffers when an external modification is detected.
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
                Whether to change the title of the terminal emulator.
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
          Highlight the matching char of the character under
          the selections' cursor using the MatchingChar face.
        '';
      };

      wrapLines = mkOption {
        type = types.nullOr (types.submodule {
          options = {
             enable = mkEnableOption "Wrap lines";

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
               type = types.nullOr types.string;
               default = null;
               description = ''
                 Prefix wrapped lines with marker text.
                 If indent = true, the marker text will be displayed in the indentation if possible.
               '';
             };
          };
        });

        default = null;
        description = ''
          Settings for the line wrapping highlighter.
        '';
      };

      numberLines = mkOption {
        type = types.nullOr (types.submodule {
          options = {
            enable = mkEnableOption "Show line numbers";
           
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
                Highlight the cursor with a separate face.
              '';
            };

            separator = mkOption {
              type = types.nullOr types.string;
              default = null;
              description = ''
                String that separates the line number column from the buffer contents.
                Defaults to "|".
              '';
            };
          };
        });
        
        default = null;
        description = ''
          Settings for the line numbering highlighter.
        '';
      };

      showWhitespace = mkOption {
        type = types.nullOr (types.submodule {
          options = {
            enable = mkEnableOption "Show whitespace";
       
            lineFeed = mkOption {
              type = types.nullOr types.string;
              default = null;
              description = ''
                The character to display for line feeds.
              '';
            };

            space = mkOption {
              type = types.nullOr types.string;
              default = null;
              description = ''
                The character to display for spaces.
              '';
            };

            nonBreakableSpace = mkOption {
              type = types.nullOr types.string;
              default = null;
              description = ''
                The character to display for non-breakable spaces.
              '';
            };

            tab = mkOption {
              type = types.nullOr types.string;
              default = null;
              description = ''
                The character to display for tabs.
              '';
            };

            tabStop = mkOption {
              type = types.nullOr types.string;
              default = null;
              description = ''
                The character to append to tabs to reach the width of a tabstop.
              '';
            };
          };
        });
        default = null;
        description = ''
          Settings for the show_whitespaces highlighter.
          By default, spaces will be shown as "·", non-breaking
          spaces as "⍽", line breaks as "¬", and tabs as "→".
        '';
      };
    };
  };

  configFile = pkgs.writeText "kakrc" ((if cfg.config != null then with cfg.config;
    let wrapOptions = with wrapLines; concatStrings [
          "${optionalString word " -word"}"
          "${optionalString indent " -indent"}"
          "${optionalString (marker != null) " -marker ${marker}"}"
          "${optionalString (maxWidth != null) " -width ${toString maxWidth}"}"
        ];
        numberLinesOptions = with numberLines; concatStrings [
          "${optionalString relative " -relative "}"
          "${optionalString highlightCursor " -hlcursor"}"
          "${optionalString (separator != null) " -separator ${separator}"}"
        ]; 
        uiOptions = with ui; concatStringsSep " " (map (s: "ncurses_"+ s) [
          "set_title=${if setTitle then "true" else "false"}"
          "status_on_top=${if (statusLine == "top") then "true" else "false"}"
          "assistant=${assistant}"
          "enable_mouse=${if enableMouse then "true" else "false"}"
        ]);
    in  ''
    ${optionalString (tabStop != null) "set-option global tabstop ${toString tabStop}"}
    ${optionalString (indentWidth != null) "set-option global indentwidth ${toString indentWidth}"}
    ${optionalString (!incrementalSearch) "set-option global incsearch false"}
    ${optionalString (alignWithTabs) "set-option global aligntab true"}
    ${optionalString (autoInfo != null) "set-option global autoinfo ${concatStringsSep "|" autoInfo}"}
    ${optionalString (autoComplete != null) "set-option global autocomplete ${concatStringsSep "|" autoComplete}"}
    ${optionalString (autoReload != null) "set-option global/ autoreload ${autoReload}"}
    ${optionalString (wrapLines != null && wrapLines.enable) "add-highlighter global/ wrap${wrapOptions}"}
    ${optionalString (numberLines != null && numberLines.enable)
      "add-highlighter global/ number-lines${numberLinesOptions}"}
    ${optionalString showMatching "add-highlighter global/ show-matching"}
    ${optionalString (scrollOff != null)
      "set-option global scrolloff ${toString scrollOff.lines},${toString scrollOff.columns}"}
    ${optionalString (ui != null) "set-option global ui_options ${uiOptions}"}
  '' else "") + "\n" + cfg.extraConfig);

in
{
  options = {
    programs.kakoune = {
      enable = mkEnableOption "kakoune text editor.";
 
      config = mkOption {
        type = types.nullOr configModule;
        default = {};
        description = "kakoune configuration options.";
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Extra configuration lines to add to ~/.config/kak/kakrc.";
      };
    };
  };

  config = mkIf cfg.enable(mkMerge [
    {
      home.packages = [ pkgs.kakoune ];
      xdg.configFile."kak/kakrc-test".source = configFile;
    }
  ]);
}
