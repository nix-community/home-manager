{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.vscode;

in

{
  options = {
    programs.vscode = {
      enable = mkEnableOption "Visual Studio Code";

      userSettings = mkOption {
        type = types.attrs;
        default = {};
        example = literalExample ''
          {
            "update.channel" = "none";
            "[nix]"."editor.tabSize" = 2;
          }
        '';
        description = ''
          Configuration written to
          <filename>~/.config/Code/User/settings.json</filename>.
        '';
      };

      userKeybindings = mkOption {
        type = types.listOf types.attrs;
        default = [];
        example = literalExample ''
          [
            {
              "key": "ctrl+h",
              "command": "workbench.action.navigateLeft"
            }
          ]
        '';
        description = ''
          Configuration written to
          <filename>~/.config/Code/User/keybindings.json</filename>.
        '';
      };

      extensions = mkOption {
        type = types.listOf types.package;
        default = [];
        description = ''
          The extensions Visual Studio Code should be started with.
          These will override but not delete manually installed ones.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      (pkgs.vscode-with-extensions.override {
        vscodeExtensions = cfg.extensions;
      })
    ];

    xdg.configFile."Code/User/settings.json".text =
      builtins.toJSON cfg.userSettings;

    xdg.configFile."Code/User/keybindings.json".text =
      builtins.toJSON cfg.userKeybindings;
  };
}
