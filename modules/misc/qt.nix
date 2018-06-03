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

      systemdServicePath = mkOption {
        type = types.envVar;
        default = lib.makeSearchPath "bin" [
          "/etc/profiles/per-user/%u"
          "%h/.nix-profile"
          "/nix/var/nix/profiles/default"
          "/run/current-system/sw"
        ];
        visible = false;
        description = ''
          Path to use for systemd services that run Qt 5 applications.
          This is to ensure that the application is able to locate any
          necessary Qt plugins.
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
        --set $HOME/.config/Trolltech.conf Qt style GTK+
    '';
  };
}
