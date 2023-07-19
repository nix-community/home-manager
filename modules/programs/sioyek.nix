{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.sioyek;

  renderConfig = generators.toKeyValue {
    mkKeyValue = key: value: "${key} ${value}";
    listsAsDuplicateKeys = true;
  };

in {
  options = {
    programs.sioyek = {
      enable = mkEnableOption
        "Sioyek, a PDF viewer designed for reading research papers and technical books";

      package = mkOption {
        default = pkgs.sioyek;
        defaultText = literalExpression "pkgs.sioyek";
        type = types.package;
        description = "Package providing the sioyek binary";
      };

      bindings = mkOption {
        description = ''
          Input configuration written to
          {file}`$XDG_CONFIG_HOME/sioyek/keys_user.config`.
          See <https://github.com/ahrm/sioyek/blob/main/pdf_viewer/keys.config>.

          Each attribute could also accept a list of strings to set multiple
          bindings of the same command.
        '';
        type = with types; attrsOf (either str (listOf str));
        default = { };
        example = literalExpression ''
          {
            "move_up" = "k";
            "move_down" = "j";
            "move_left" = "h";
            "move_right" = "l";
            "screen_down" = [ "d" "<C-d>" ];
            "screen_up" = [ "u" "<C-u>" ];
          }
        '';
      };

      config = mkOption {
        description = ''
          Input configuration written to
          {file}`$XDG_CONFIG_HOME/sioyek/prefs_user.config`.
          See <https://github.com/ahrm/sioyek/blob/main/pdf_viewer/prefs.config>.
        '';
        type = types.attrsOf types.str;
        default = { };
        example = literalExpression ''
          {
            "background_color" = "1.0 1.0 1.0";
            "text_highlight_color" = "1.0 0.0 0.0";
          }
        '';
      };

    };
  };

  config = mkIf cfg.enable (mkMerge [
    { home.packages = [ cfg.package ]; }
    (mkIf (cfg.config != { }) {
      xdg.configFile."sioyek/prefs_user.config".text = renderConfig cfg.config;
    })
    (mkIf (cfg.bindings != { }) {
      xdg.configFile."sioyek/keys_user.config".text = renderConfig cfg.bindings;
    })
  ]);

  meta.maintainers = [ hm.maintainers.podocarp ];
}
