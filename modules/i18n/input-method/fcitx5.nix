{ config, pkgs, lib, ... }:

with lib;

let
  im = config.i18n.inputMethod;
  cfg = im.fcitx5;
  fcitx5Package = cfg.fcitx5-with-addons.override { inherit (cfg) addons; };
in {
  options = {
    i18n.inputMethod.fcitx5 = {
      fcitx5-with-addons = mkOption {
        type = types.package;
        default = pkgs.libsForQt5.fcitx5-with-addons;
        example = literalExpression "pkgs.kdePackages.fcitx5-with-addons";
        description = ''
          The fcitx5 package to use.
        '';
      };
      addons = mkOption {
        type = with types; listOf package;
        default = [ ];
        example = literalExpression "with pkgs; [ fcitx5-rime ]";
        description = ''
          Enabled Fcitx5 addons.
        '';
      };

      waylandFrontend = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Use the Wayland input method frontend.
          See [Using Fcitx 5 on Wayland](https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland).
        '';
      };
    };
  };

  config = mkIf (im.enabled == "fcitx5") {
    i18n.inputMethod.package = fcitx5Package;

    home.sessionVariables = {
      GLFW_IM_MODULE = "ibus"; # IME support in kitty
      XMODIFIERS = "@im=fcitx";
      QT_PLUGIN_PATH =
        "$QT_PLUGIN_PATH\${QT_PLUGIN_PATH:+:}${fcitx5Package}/${pkgs.qt6.qtbase.qtPluginPrefix}";
    } // lib.optionalAttrs (!cfg.waylandFrontend) {
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
    };

    systemd.user.services.fcitx5-daemon = {
      Unit = {
        Description = "Fcitx5 input method editor";
        PartOf = [ "graphical-session.target" ];
      };
      Service.ExecStart = "${fcitx5Package}/bin/fcitx5";
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };

}
