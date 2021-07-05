{ config, pkgs, lib, ... }:

with lib;

let cfg = config.i18n.inputMethod.uim;
in {
  options = {

    i18n.inputMethod.uim = {
      toolbar = mkOption {
        type = types.enum [ "gtk" "gtk3" "gtk-systray" "gtk3-systray" "qt4" ];
        default = "gtk";
        example = "gtk-systray";
        description = ''
          Selected UIM toolbar.
        '';
      };
    };

  };

  config = mkIf (config.i18n.inputMethod.enabled == "uim") {
    i18n.inputMethod.package = pkgs.uim;

    home.sessionVariables = {
      GTK_IM_MODULE = "uim";
      QT_IM_MODULE = "uim";
      XMODIFIERS = "@im=uim";
    };

    systemd.user.services.uim-daemon = {
      Unit = {
        Description = "Uim input method editor";
        PartOf = [ "graphical-session.desktop" ];
      };
      Service.ExecStart = toString
        (pkgs.writeShellScript "start-uim-xim-and-uim-toolbar" ''
          ${pkgs.uim}/bin/uim-xim &
          ${pkgs.uim}/bin/uim-toolbar-${cfg.toolbar}
        '');
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };

}
