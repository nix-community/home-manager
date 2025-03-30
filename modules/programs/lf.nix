{ config, lib, pkgs, ... }:
let
  inherit (lib)
    concatStringsSep literalExpression mapAttrsToList mkOption optionalString
    types;

  cfg = config.programs.lf;
in {
  meta.maintainers = [ lib.hm.maintainers.owm111 ];

  options = {
    programs.lf = {
      enable = lib.mkEnableOption "lf";

      package = lib.mkPackageOption pkgs "lf" { };

      settings = mkOption {
        type = with types;
          attrsOf (oneOf [ str int (listOf (either str int)) bool ]);
        default = { };
        example = {
          tabstop = 4;
          number = true;
          ratios = [ 1 1 2 ];
        };
        description = ''
          An attribute set of lf settings. See the lf documentation for
          detailed descriptions of these options. Prefer
          {option}`programs.lf.previewer.*` for setting lf's {var}`previewer`
          option. All string options are quoted with double quotes.
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
        example = literalExpression ''{ "<c-g>" = "cmd-escape"; }'';
        description = ''
          Keys to bind to command line commands which can only be one of the
          builtin commands. Keys set to null or an empty string are deleted.
        '';
      };

      previewer.source = mkOption {
        type = with types; nullOr path;
        default = null;
        example = literalExpression ''
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
          {var}`previewer` option.
        '';
      };

      previewer.keybinding = mkOption {
        type = with types; nullOr str;
        default = null;
        example = "i";
        description = ''
          Key to bind to the script at {var}`previewer.source` and
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

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."lf/lfrc".text = let
      fmtSetting = k: v:
        optionalString (v != null) "set ${
          if lib.isBool v then
            "${optionalString (!v) "no"}${k}"
          else if lib.isList v then
            ''${k} "${concatStringsSep ":" (map (w: toString w) v)}"''
          else
            "${k} ${if lib.isInt v then toString v else ''"${v}"''}"
        }";

      settingsStr = concatStringsSep "\n"
        (lib.remove "" (mapAttrsToList fmtSetting cfg.settings));

      fmtCmdMap = before: k: v:
        "${before} ${k}${optionalString (v != null && v != "") " ${v}"}";
      fmtCmd = fmtCmdMap "cmd";
      fmtMap = fmtCmdMap "map";
      fmtCmap = fmtCmdMap "cmap";

      commandsStr = concatStringsSep "\n" (mapAttrsToList fmtCmd cfg.commands);
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
}
