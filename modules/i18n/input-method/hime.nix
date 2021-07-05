{ config, pkgs, lib, ... }:

with lib; {
  config = mkIf (config.i18n.inputMethod.enabled == "hime") {
    i18n.inputMethod.package = pkgs.hime;

    home.sessionVariables = {
      GTK_IM_MODULE = "hime";
      QT_IM_MODULE = "hime";
      XMODIFIERS = "@im=hime";
    };

    systemd.user.services.hime-daemon = {
      Unit = {
        Description = "Hime input method editor";
        PartOf = [ "graphical-session.desktop" ];
      };
      Service.ExecStart = "${pkgs.hime}/bin/hime";
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };

}
