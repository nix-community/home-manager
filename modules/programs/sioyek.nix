{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.programs.sioyek;

  renderAttrs = attrs:
    concatStringsSep "\n"
    (mapAttrsToList (name: value: "${name} ${value}") attrs);
in {
  options = {
    programs.sioyek = {
      enable = mkEnableOption
        "Sioyek is a PDF viewer designed for reading research papers and technical books.";

      package = mkOption {
        default = pkgs.sioyek;
        defaultText = literalExpression "pkgs.sioyek";
        type = types.package;
        description = "Package providing the sioyek binary";
      };

      bindings = mkOption {
        description = ''
          Input configuration written to
          <filename>$XDG_CONFIG_HOME/sioyek/keys_user.config</filename>.
          See <link xlink:href="https://github.com/ahrm/sioyek/blob/main/pdf_viewer/keys.config"/>.
        '';
        type = types.attrsOf types.str;
        default = { };
        example = literalExpression ''
          {
            "move_up" = "k";
            "move_down" = "j";
            "move_left" = "h";
            "move_right" = "l";
          }
        '';
      };

      config = mkOption {
        description = ''
          Input configuration written to
          <filename>$XDG_CONFIG_HOME/sioyek/prefs_user.config</filename>.
          See <link xlink:href="https://github.com/ahrm/sioyek/blob/main/pdf_viewer/prefs.config"/>.
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
      xdg.configFile."sioyek/prefs_user.config".text = renderAttrs cfg.config;
    })
    (mkIf (cfg.bindings != { }) {
      xdg.configFile."sioyek/keys_user.config".text = renderAttrs cfg.bindings;
    })
  ]);

  meta.maintainers = [ hm.maintainers.podocarp ];
}
