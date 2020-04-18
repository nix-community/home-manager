{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.lf;

  knownSettings = {
    anchorfind = types.bool;
    color256 = types.bool;
    dircounts = types.bool;
    dirfirst = types.bool;
    drawbox = types.bool;
    globsearch = types.bool;
    icons = types.bool;
    hidden = types.bool;
    ignorecase = types.bool;
    ignoredia = types.bool;
    incsearch = types.bool;
    preview = types.bool;
    reverse = types.bool;
    smartcase = types.bool;
    smartdia = types.bool;
    wrapscan = types.bool;
    wrapscroll = types.bool;
    number = types.bool;
    relativenumber = types.bool;
    findlen = types.int;
    period = types.int;
    scrolloff = types.int;
    tabstop = types.int;
    errorfmt = types.str;
    filesep = types.str;
    ifs = types.str;
    promptfmt = types.str;
    shell = types.str;
    sortby = types.str;
    timefmt = types.str;
    ratios = types.str;
    info = types.str;
    shellopts = types.str;
  };

  lfSettingsType = types.submodule {
    options = let
      opt = name: type:
        mkOption {
          type = types.nullOr type;
          default = null;
          visible = false;
        };
    in mapAttrs opt knownSettings;
  };
in {
  options = {
    programs.lf = {
      enable = mkEnableOption "lf";

      settings = mkOption {
        type = lfSettingsType;
        default = { };
        example = { tabstop = 4; number = true; ratios = "1:1:2"; };
        description = ''
          An attribute set of lf settings. The attribute names and cooresponding
          values must be among the following supported options.

          <informaltable frame="none"><tgroup cols="1"><tbody>
          ${concatStringsSep "\n" (mapAttrsToList (n: v: ''
            <row>
              <entry><varname>${n}</varname></entry>
              <entry>${v.description}</entry>
            </row>
          '') knownSettings)}
          </tbody></tgroup></informaltable>

          See the lf documentation for detailed descriptions of these options.
          Note, use <varname>previewer</varname> to set lf's
          <varname>previewer</varname> option, and
          <varname>extraConfig</varname> for any other option not listed above.
          All string options are quoted with double quotes.
        '';
      };

      commands = mkOption {
        type = with types; attrsOf (nullOr str);
        default = { };
        example = {
          get-mime-type = ''%xdg-mime query filetype "$f"'';
          open = "$$OPENER $f";
        };
        description = ''
          Commands to declare. Commands set to null or an empty string are
          deleted.
        '';
      };

      keybindings = mkOption {
        type = with types; attrsOf (nullOr str);
        default = { };
        example = {
          gh = "cd ~";
          D = "trash";
          i = "$less $f";
          U = "!du -sh";
          gg = null;
        };
        description =
          "Keys to bind. Keys set to null or an empty string are deleted.";
      };

      cmdKeybindings = mkOption {
        type = with types; attrsOf (nullOr str);
        default = { };
        example = { "<c-g>" = "cmd-escape"; };
        description = ''
          Keys to bind to command line commands which can only be one of the
          builtin commands. Keys set to null or an empty string are deleted.
        '';
      };

      previewer.source = mkOption {
        type = with types; nullOr path;
        default = null;
        example = literalExample ''
          pkgs.writeShellScript "pv.sh" '''
            #!/bin/sh

            case "$1" in
                *.tar*) tar tf "$1";;
                *.zip) unzip -l "$1";;
                *.rar) unrar l "$1";;
                *.7z) 7z l "$1";;
                *.pdf) pdftotext "$1" -;;
                *) highlight -O ansi "$1" || cat "$1";;
            esac
          '''
        '';
        description = ''
          Script or executable to use to preview files. Sets lf's
          <varname>previewer</varname> option.
        '';
      };

      previewer.keybinding = mkOption {
        type = with types; nullOr str;
        default = null;
        example = "i";
        description = ''
          Key to bind to the script at <varname>previewer.source</varname> and
          pipe through less. Setting to null will not bind any key.
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        example = ''
          $mkdir -p ~/.trash
        '';
        description = "Custom lfrc lines.";
      };
    };
  };

  config = let

  in mkIf cfg.enable {
    home.packages = [ pkgs.lf ];

    xdg.configFile = {
      "lf/lfrc".text = let
        fmtSetting = k: v:
          optionalString (v != null) "set ${
            if isBool v then
              "${optionalString (!v) "no"}${k}"
            else
              "${k} ${if isInt v then toString v else ''"${v}"''}"
          }";

        settingsStr = concatStringsSep "\n"
          (filter (x: x != "") (mapAttrsToList fmtSetting cfg.settings));

        fmtCmdMap = before: k: v:
          "${before} ${k}${optionalString (v != null && v != "") " ${v}"}";
        fmtCmd = fmtCmdMap "cmd";
        fmtMap = fmtCmdMap "map";
        fmtCmap = fmtCmdMap "cmap";

        commandsStr =
          concatStringsSep "\n" (mapAttrsToList fmtCmd cfg.commands);
        keybindingsStr =
          concatStringsSep "\n" (mapAttrsToList fmtMap cfg.keybindings);
        cmdKeybindingsStr =
          concatStringsSep "\n" (mapAttrsToList fmtCmap cfg.cmdKeybindings);

        previewerStr = optionalString (cfg.previewer.source != null) ''
          set previewer ${cfg.previewer.source}
          ${optionalString (cfg.previewer.keybinding != null) ''
            map ${cfg.previewer.keybinding} ''$${cfg.previewer.source} "$f" | less -R
          ''}
        '';
      in ''
        ${settingsStr}

        ${commandsStr}

        ${keybindingsStr}

        ${cmdKeybindingsStr}

        ${previewerStr}

        ${cfg.extraConfig}
      '';
    };
  };
}
