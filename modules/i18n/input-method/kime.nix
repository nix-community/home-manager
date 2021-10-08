{ config, pkgs, lib, generators, ... }:
with lib;
let
  cfg = config.i18n.inputMethod.kime;
  yamlFormat = pkgs.formats.yaml { };
in {
  options = {
    i18n.inputMethod.kime = {
      config = mkOption {
        type = yamlFormat.type;
        default = { };
        example = literalExpression ''
          {
            daemon = {
              modules = ["Xim" "Indicator"];
            };

            indicator = {
              icon_color = "White";
            };

            engine = {
              hangul = {
                layout = "dubeolsik";
              };
            };
          }
        '';
        description = ''
          kime configuration. Refer to
          <link xlink:href="https://github.com/Riey/kime/blob/develop/docs/CONFIGURATION.md"/>
          for details on supported values.
        '';
      };
    };
  };

  config = mkIf (config.i18n.inputMethod.enabled == "kime") {
    i18n.inputMethod.package = pkgs.kime;

    home.sessionVariables = {
      GTK_IM_MODULE = "kime";
      QT_IM_MODULE = "kime";
      XMODIFIERS = "@im=kime";
    };

    xdg.configFile."kime/config.yaml".text =
      replaceStrings [ "\\\\" ] [ "\\" ] (builtins.toJSON cfg.config);

    systemd.user.services.kime-daemon = {
      Unit = { Description = "Kime input method editor"; };
      PartOf = [ "graphical-session.target" ];
      Service.ExecStart = "${pkgs.kime}/bin/kime";
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };

}
