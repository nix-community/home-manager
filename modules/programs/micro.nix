{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.micro;

  jsonFormat = pkgs.formats.json { };

in {
  meta.maintainers = [ hm.maintainers.mforster ];

  options = {
    programs.micro = {
      enable = mkEnableOption "micro, a terminal-based text editor";

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
          {file}`$XDG_CONFIG_HOME/micro/settings.json`. See
          <https://github.com/zyedidia/micro/blob/master/runtime/help/options.md>
          for supported values.
        '';
      };

      keybinds = mkOption {
        type = jsonFormat.type;
        default = {
          "Alt-/" = "lua:comment.comment";
          "CtrlUnderscore" = "lua:comment.comment";
        };
        example = literalExpression ''
          {
            "Ctrl-y" = "Undo";
            "Ctrl-z" = "Redo";
          }
        '';
        description = ''
          Configuration written to
          {file}`$XDG_CONFIG_HOME/micro/bindings.json`. See
          <https://github.com/zyedidia/micro/blob/master/runtime/help/keybindings.md>
          for supported values.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.micro ];

    xdg.configFile."micro/settings.json".source =
      jsonFormat.generate "micro-settings" cfg.settings;

    xdg.configFile."micro/bindings.json".source =
      jsonFormat.generate "micro-keybinds" cfg.keybinds;
  };
}
