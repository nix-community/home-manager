{ config, pkgs, lib, ... }:

with lib;

let
  im = config.i18n.inputMethod;
  cfg = im.ibus;
  impanel = optionalString (cfg.panel != null) "--panel=${cfg.panel}";
  ibusPackage = pkgs.ibus-with-plugins.override { inherit (cfg) engines; };
in {
  options = {
    i18n.inputMethod.ibus = {
      engines = mkOption {
        type = with types; listOf ibusEngine;
        default = [ ];
        example = literalExpression "with pkgs.ibus-engines; [ mozc hangul ]";
        description = ''
          Enabled IBus engines.
        '';
      };
    };
    panel = mkOption {
      type = with types; nullOr path;
      default = null;
      example = literalExpression ''
        "''${pkgs.plasma5Packages.plasma-desktop}/libexec/kimpanel-ibus-panel"'';
      description = ''
        Replace the IBus panel with another panel.
      '';
    };
  };

  config = mkIf (im.enabled == "ibus") {
    i18n.inputMethod.package = ibusPackage;

    home.sessionVariables = {
      GLFW_IM_MODULE = "ibus";
      GTK_IM_MODULE = "ibus";
      QT_IM_MODULE = "ibus";
      XMODIFIERS = "@im=ibus";
    };

    # Without dconf enabled it is impossible to use IBus
    programs.dconf.enable = true;

    programs.dconf.packages = [ ibusPackage ];

    services.dbus.packages = [ ibusPackage ];

    xdg.portal.extraPortals = mkIf config.xdg.portal.enable [ ibusPackage ];

    systemd.user.services.ibus-daemon = {
      Unit = {
        Description = "IBus input method editor";
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${ibusPackage}/bin/ibus-daemon --replace --xim ${impanel}";
        ExecReload = "${ibusPackage}/bin/ibus restart";
        ExecStop = "${ibusPackage}/bin/ibus exit";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
