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
          If <literal>0</literal>, a tab will be used instead.
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
          The kakoune default is <literal>[ "command" "onkey" ]</literal>
        '';
        example = [ "command" "normal" ];
      };

      autoComplete = mkOption {
        type = types.nullOr(types.listOf (types.enum [  "insert" "prompt" ]));
        default = null;
        description = ''
          Modes in which to display possible completions.
          The kakoune default is <literal>[ "insert" "prompt" ]</literal>
        '';
      };

      autoReload = mkOption {
        type = types.nullOr (types.enum [ "yes" "no" "ask" ]);
        default = null;
        description = ''
          Whether to reload buffers when an external modification is detected.
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
                 If <literal>true</literal>,
                 the marker text will be displayed in the indentation if possible.
               '';
               example = "⏎";
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
                The kakoune default is <literal>"|"</literal>.
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
                The kakoune default is <literal>"¬"</literal>.
              '';
            };

            space = mkOption {
              type = types.nullOr types.string;
              default = null;
              description = ''
                The character to display for spaces.
                The kakoune default is <literal>"·"</literal>.
              '';
            };

            nonBreakingSpace = mkOption {
              type = types.nullOr types.string;
              default = null;
              description = ''
                The character to display for non-breaking spaces.
                The kakoune default is <literal>"⍽"</literal>.
              '';
            };

            tab = mkOption {
              type = types.nullOr types.string;
              default = null;
              description = ''
                The character to display for tabs.
                The kakoune default is <literal>"→"</literal>.
              '';
            };

            tabStop = mkOption {
              type = types.nullOr types.string;
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
          Settings for the show_whitespaces highlighter.
        '';
      };

      keyMappings = mkOption {
        type = types.listOf (types.submodule {
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

              description = ''
                The mode in which the mapping takes effect.
              '';
              example = "user";
            };
            
            docstring = mkOption {
              type = types.nullOr types.string;
              default = null;
              description = ''
                Optional documentation text to display
                in info boxes.
              '';
            };

            key = mkOption {
              type = types.string;
              description = ''
                The key to be mapped. See
                https://github.com/mawww/kakoune/blob/master/doc/pages/mapping.asciidoc#mappable-keys
                for possible values.
              '';
              example = "<a-x>";
            };

            effect = mkOption {
              type = types.string;
              description = ''
                The sequence of keys to be mapped.
              '';
              example = ":wq<ret>";
            };
          };
        });

        default = [];
        description = ''
          User-defined key mappings.
        '';
      };

      hooks = mkOption {
        type = types.listOf (types.submodule {
          options = {
            name = mkOption {
              type = types.enum [
                "NormalBegin" "NormalIdle" "NormalEnd" "NormalKey"
                "InsertBegin" "InsertIdle" "InsertEnd" "InsertKey" "InsertChar" "InsertDelete" "InsertMove" 
                "WinCreate" "WinClose" "WinResize" "WinDisplay" "WinSetOption"
                "BufSetOption" "BufNewFile" "BufOpenFile" "BufCreate" "BufWritePre" "BufWritePost"
                "BufReload" "BufClose" "BufOpenFifo" "BufReadFifo" "BufCloseFifo"
                "RuntimeError" "ModeChange" "PromptIdle" "GlobalSetOption"
                "KakBegin" "KakEnd" "FocusIn" "FocusOut" "RawKey"
                "InsertCompletionShow" "InsertCompletionHide" "InsertCompletionSelect"
              ];

              description = ''
                The name of the hook. For a description, see
                https://github.com/mawww/kakoune/blob/master/doc/pages/hooks.asciidoc#default-hooks. 
              '';
              example = "SetOption";
            };

            once = mkOption {
              type = types.bool;
              default = false;
              description = ''
                Remove the hook after running it once.
              '';
            };

            group = mkOption {
              type = types.nullOr types.string;
              default = null;
              description = ''
                Add the hook to the named group.
              '';
            };

            option = mkOption {
              type = types.nullOr types.string;
              default = null;
              description = ''
                Additional option to pass to the hook.
              '';
              example = "filetype=latex";
            };

            commands = mkOption {
              type = types.lines;
              default = "";
              description = ''
                Commands to run when the hook is activated.
              '';
              example = ''
                set-option window indentwidth 2
              '';
            };
          };
        });

        default = [];
        description = ''
          Global hooks. For documentation, see
          https://github.com/mawww/kakoune/blob/master/doc/pages/hooks.asciidoc.
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
    ${concatStringsSep "\n" (map keyMappingString keyMappings)}
    ${concatStringsSep "\n" (map hookString hooks)}
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
