{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.qt;
  dag = config.lib.dag;

in

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    qt = {
      enable = mkEnableOption "Qt 4 and 5 configuration";

      useGtkTheme = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether Qt 4 and 5 should be set up to use the GTK theme
          settings.
        '';
      };
    };
  };

  config = mkIf (cfg.enable && cfg.useGtkTheme) {
    home.sessionVariables.QT_QPA_PLATFORMTHEME = "gtk2";
    home.packages = [ pkgs.libsForQt5.qtstyleplugins ];
    xsession.profileExtra =
      "systemctl --user import-environment QT_QPA_PLATFORMTHEME";

    home.activation.useGtkThemeInQt4 = dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD ${pkgs.crudini}/bin/crudini $VERBOSE_ARG \
        --set "${config.xdg.configHome}/Trolltech.conf" Qt style GTK+
    '';
  };
}
