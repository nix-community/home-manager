{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.micro;

  jsonFormat = pkgs.formats.json { };

in {
  meta.maintainers = [ hm.maintainers.mforster maintainers.pbsds ];

  options = {
    programs.micro = {
      enable = mkEnableOption "micro, a terminal-based text editor";

      trueColor = mkOption {
        type = types.bool;
        default = true;
        description =
          "Enables support for the whole color range, should the terminal allow.";
      };

      settings = mkOption {
        type = jsonFormat.type;
        default = { };
        example = literalExpression ''
          {
            autosu = false;
            cursorline = false;
          }
        '';
        description = ''
          Configuration written to
          <filename>$XDG_CONFIG_HOME/micro/settings.json</filename>. See
          <link xlink:href="https://github.com/zyedidia/micro/blob/master/runtime/help/options.md"/>
          for supported values.
        '';
      };

      bindings = mkOption {
        type = jsonFormat.type;
        default = { };
        example = literalExpression ''
          {
            "Alt-d" = "SpawnMultiCursor";
            "Escape" = "RemoveAllMultiCursors";
            "CtrlDown" = "None";
            "CtrlUp" = "None";
            "Shift-PageDown" = "SelectPageDown";
            "Shift-PageUp" = "SelectPageUp";
          }
        '';
        description = ''
          Configuration written to
          <filename>$XDG_CONFIG_HOME/micro/bindings.json</filename>. See
          <link xlink:href="https://github.com/zyedidia/micro/blob/master/runtime/help/keybindings.md"/>
          for supported values.
        '';
      };

      ensurePlugins = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = literalExpression ''
          [
            "aspell"
          ]
        '';
        description = ''
          Install micro plugins during activation. See
          <link xlink:href="https://micro-editor.github.io/plugins.html"/>
          for a listing of available plugins.
        '';

      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.micro ];

    home.sessionVariables = mkIf cfg.trueColor { MICRO_TRUECOLOR = "1"; };

    xdg.configFile."micro/settings.json".source =
      jsonFormat.generate "micro-settings" cfg.settings;

    xdg.configFile."micro/bindings.json".source =
      jsonFormat.generate "micro-bindings" cfg.bindings;

    home.activation = let
      mkInstall = pluginName: ''
        if ! test -d ${config.xdg.configHome}/micro/plug/${
          lib.escapeShellArg pluginName
        }; then
          (set -x
            $DRY_RUN_CMD ${pkgs.micro}/bin/micro -plugin install ${
              lib.escapeShellArg pluginName
            }
          )
        fi
      '';
      installs = lib.concatStringsSep "\n" (map mkInstall cfg.ensurePlugins);
    in mkIf (cfg.ensurePlugins != [ ]) {
      microPluginSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] installs;
    };
  };
}
