{ config, pkgs, lib, ... }:

let
  inherit (lib) literalExpression mkIf mkOption mkRemovedOptionModule types;

  cfg = config.i18n.inputMethod.kime;
in {
  imports = [
    (mkRemovedOptionModule [ "i18n" "inputMethod" "kime" "config" ] ''
      Please use 'i18n.inputMethod.kime.extraConfig' instead.
    '')
  ];

  options = {
    i18n.inputMethod.kime = {
      extraConfig = mkOption {
        type = types.lines;
        default = "";
        example = literalExpression ''
          daemon:
            modules: [Xim,Indicator]
          indicator:
            icon_color: White
          engine:
            hangul:
              layout: dubeolsik
        '';
        description = ''
          kime configuration. Refer to
          <https://github.com/Riey/kime/blob/develop/docs/CONFIGURATION.md>
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

    xdg.configFile."kime/config.yaml".text = cfg.extraConfig;

    systemd.user.services.kime-daemon = {
      Unit = {
        Description = "Kime input method editor";
        PartOf = [ "graphical-session.target" ];
      };
      Service.ExecStart = "${pkgs.kime}/bin/kime";
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
