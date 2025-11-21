{
  config,
  pkgs,
  lib,
  ...
}:
let
  im = config.i18n.inputMethod;
in
{
  config = lib.mkIf (im.enable && im.type == "nabi") {
    i18n.inputMethod.package = pkgs.nabi;

    home.sessionVariables = {
      GTK_IM_MODULE = "nabi";
      QT_IM_MODULE = "nabi";
      XMODIFIERS = "@im=nabi";
    };

    systemd.user.services.nabi-daemon = {
      Unit = {
        Description = "Nabi input method editor";
        PartOf = [ "graphical-session.desktop" ];
      };
      Service.ExecStart = "${pkgs.nabi}/bin/nabi";
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };

}
