{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.zed-editor;
  jsonFormat = pkgs.formats.json { };

  mergedSettings = cfg.userSettings // {
    # this part by @cmacrae
    auto_install_extensions = lib.listToAttrs
      (map (ext: lib.nameValuePair ext true) cfg.extensions);
  };
in {
  meta.maintainers = [ maintainers.libewa ];
  options = {
    programs.zed-editor = {
      enable = mkEnableOption
        "Zed, the high performance, multiplayer code editor from the creators of Atom and Tree-sitter";
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
            features = {
              copilot = false;
            };
            telemetry = {
              metrics = false;
            };
            vim_mode = false;
            ui_font_size = 16;
            buffer_font_size = 16;
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
              context = "Workspace";
              bindings = {
                ctrl-shift-t = "workspace::NewTerminal";
              };
            };
          ]
        '';
        description = ''
          Configuration written to Zed's {file}`keymap.json`.
        '';
      };
      extensions = mkOption {
        type = types.listOf types.str;
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
    xdg.configFile."zed/settings.json" = (mkIf (mergedSettings != { }) {
        source = jsonFormat.generate "zed-user-settings" mergedSettings;
    });
    xdg.configFile."zed/keymap.json" = (mkIf (cfg.userKeymaps != { }) {
        source = jsonFormat.generate "zed-user-keymaps" cfg.userKeymaps;
    });
  };
}
