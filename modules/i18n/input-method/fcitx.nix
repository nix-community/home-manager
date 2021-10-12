{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.i18n.inputMethod.fcitx;
  fcitxPackage = pkgs.fcitx.override { plugins = cfg.engines; };
  fcitxEngine = types.package // {
    name = "fcitx-engine";
    check = x:
      types.package.check x && attrByPath [ "meta" "isFcitxEngine" ] false x;
  };
in {
  options = {

    i18n.inputMethod.fcitx = {
      engines = mkOption {
        type = with types; listOf fcitxEngine;
        default = [ ];
        example = literalExpression "with pkgs.fcitx-engines; [ mozc hangul ]";
        description = let
          enginesDrv = filterAttrs (const isDerivation) pkgs.fcitx-engines;
          engines = concatStringsSep ", "
            (map (name: "<literal>${name}</literal>") (attrNames enginesDrv));
        in "Enabled Fcitx engines. Available engines are: ${engines}.";
      };
    };

  };

  config = mkIf (config.i18n.inputMethod.enabled == "fcitx") {
    i18n.inputMethod.package = fcitxPackage;

    home.sessionVariables = {
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
    };

    systemd.user.services.fcitx-daemon = {
      Unit = {
        Description = "Fcitx input method editor";
        PartOf = [ "graphical-session.desktop" ];
      };
      Service.ExecStart = "${fcitxPackage}/bin/fcitx";
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };

}
