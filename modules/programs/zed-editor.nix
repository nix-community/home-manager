{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.zed-editor;
  jsonFormat = pkgs.formats.json { };

  configDir = if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/zed" #TODO: see if this is actually the correct directory
    else
      "${config.xdg.configHome}/zed";
  configFilePath = "${configDir}/settings.json";
  keymapFilePath = "${configDir}/keymap.json";
  mergedSettings = cfg.userSettings // { auto_install_extensions = cfg.extensions; };
in
{
  options = {
    programs.zed-editor = {
      enable = mkEnableOption "Zed, the high performance, multiplayer code editor from the creators of Atom and Tree-sitter";
      package = mkOption {
        type = types.package;
        default = pkgs.zed-editor;
        defaultText = literalExpression "pkgs.zed-editor";
        description = ''
          Another package to install instead of zed
        '';
      };
      userSettings = mkOption {
        type = jsonFormat.type;
        default = { };
        example = literalExpression ''
        {
          "features": {
            "copilot": false
          },
          "telemetry": {
            "metrics": false
          },
          "vim_mode": false,
          "ui_font_size": 16,
          "buffer_font_size": 16
        }
        '';
        description = ''
          Configuration written to Zed's {file}`settings.json`.
        '';
      };
      userKeymaps = mkOption {
        type = jsonFormat.type;
        default = { };
        example = literalExpression ''
          [
            {
              "context" = "Workspace";
              "bindings" = {
                "ctrl-shift-t" = "workspace::NewTerminal";
              };
            };
          ]
        '';
        description = ''
          Configuration written to Zed's {file}`keymap.json`.
        '';
      };
      extensions = mkOption {
        type = listOf str;
        default = [ ];
        example = literalExpression ''
          [ "swift" "nix" "xy-zed" ]
        '';
        description = ''
          A list of the extensions Zed should install on startup.
          Use the name of a repository in the [extension list](https://github.com/zed-industries/extensions/tree/main/extensions).
        '';
      };
      #TODO: add vscode option parity (installing extensions, configuring keybinds with nix etc.)
    };
  };

  config = mkIf cfg.enable {
      home.packages = [ cfg.package ];
      home.file = mkMerge [
        (mkIf (mergedSettings != { }) {
          "${configFilePath}".source =
            jsonFormat.generate "zed-user-settings" mergedSettings;
        })
        (mkIf (cfg.userKeymaps != { }) {
          "${keymapFilePath}".source =
            jsonFormat.generate "zed-user-keymaps" cfg.userKeymaps;
        })
      ];
    };
}
