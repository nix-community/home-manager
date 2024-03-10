{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.pqiv;
  iniFormat = pkgs.formats.ini { };
in {
  meta.maintainers = with lib.maintainers; [ donovanglover iynaix ];

  options.programs.pqiv = {
    enable = mkEnableOption "pqiv image viewer";

    package = mkOption {
      type = types.package;
      default = pkgs.pqiv;
      defaultText = literalExpression "pkgs.pqiv";
      description = "The pqiv package to install.";
    };

    settings = mkOption {
      type = iniFormat.type;
      default = { };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/pqivrc`. See
        {manpage}`pqiv(1)` for a list of available options. To set a
        boolean flag, set the value to 1.
      '';
      example = literalExpression ''
        {
          options = {
            lazy-load = 1;
            hide-info-box = 1;
            background-pattern = "black";
            thumbnail-size = "256x256";
            command-1 = "thunar";
          };
        };
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Extra lines to be added to {file}`$XDG_CONFIG_HOME/pqivrc`. See
        {manpage}`pqiv(1)` for a list of available options.
      '';
      example = literalExpression ''
        [actions]
        set_cursor_auto_hide(1)

        [keybindings]
        t { montage_mode_enter() }
        @MONTAGE {
          t { montage_mode_return_cancel() }
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions =
      [ (hm.assertions.assertPlatform "programs.pqiv" pkgs platforms.linux) ];

    home.packages = [ cfg.package ];

    xdg.configFile."pqivrc" =
      mkIf (cfg.settings != { } && cfg.extraConfig != "") {
        text = lib.concatLines [
          (generators.toINI { } cfg.settings)
          cfg.extraConfig
        ];
      };
  };
}
