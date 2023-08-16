{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.qt;

  # Maps known lowercase style names to style packages. Non-exhaustive.
  stylePackages = with pkgs; {
    bb10bright = libsForQt5.qtstyleplugins;
    bb10dark = libsForQt5.qtstyleplugins;
    cleanlooks = libsForQt5.qtstyleplugins;
    gtk2 = libsForQt5.qtstyleplugins;
    motif = libsForQt5.qtstyleplugins;
    cde = libsForQt5.qtstyleplugins;
    plastique = libsForQt5.qtstyleplugins;

    adwaita = adwaita-qt;
    adwaita-dark = adwaita-qt;
    adwaita-highcontrast = adwaita-qt;
    adwaita-highcontrastinverse = adwaita-qt;

    breeze = libsForQt5.breeze-qt5;

    kvantum = [
      qtstyleplugin-kvantum-qt4
      libsForQt5.qtstyleplugin-kvantum
      qt6Packages.qtstyleplugin-kvantum
    ];
  };

in {
  meta.maintainers = with maintainers; [ rycee thiagokokada ];

  imports = [
    (mkChangedOptionModule [ "qt" "useGtkTheme" ] [ "qt" "platformTheme" ]
      (config:
        if getAttrFromPath [ "qt" "useGtkTheme" ] config then "gtk" else null))
  ];

  options = {
    qt = {
      enable = mkEnableOption "Qt 4, 5 and 6 configuration";

      platformTheme = mkOption {
        type = types.nullOr (types.enum [ "gtk" "gnome" "qtct" "kde" ]);
        default = null;
        example = "gnome";
        relatedPackages = [
          "qgnomeplatform"
          [ "libsForQt5" "qtstyleplugins" ]
          [ "libsForQt5" "qt5ct" ]
          [ "qt6Packages" "qt6ct" ]
          [ "libsForQt5" "plasma-integration" ]
          [ "libsForQt5" "systemsettings" ]
        ];
        description = ''
          Platform theme to use for Qt applications.

          The options are

          `gtk`
          : Use GTK theme with
            [`qtstyleplugins`](https://github.com/qt/qtstyleplugins)

          `gnome`
          : Use GNOME theme with
            [`qgnomeplatform`](https://github.com/FedoraQt/QGnomePlatform)

          `qtct`
          : Use Qt style set using
            [`qt5ct`](https://github.com/desktop-app/qt5ct)
            and [`qt6ct`](https://github.com/trialuser02/qt6ct)
            applications

          `kde`
          : Use Qt settings from Plasma
        '';
      };

      style = {
        name = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "adwaita-dark";
          relatedPackages = [
            "adwaita-qt"
            [ "libsForQt5" "breeze-qt5" ]
            [ "libsForQt5" "qtstyleplugins" ]
            "qtstyleplugin-kvantum-qt4"
            [ "libsForQt5" "qtstyleplugin-kvantum" ]
            [ "qt6Packages" "qtstyleplugin-kvantum" ]
          ];
          description = ''
            Style to use for Qt5/Qt6 applications. Case-insensitive.

            Some examples are

            `adwaita`, `adwaita-dark`, `adwaita-highcontrast`, `adwaita-highcontrastinverse`
            : Use the Adwaita style from
              [`adwaita-qt`](https://github.com/FedoraQt/adwaita-qt)

            `breeze`
            : Use the Breeze style from
              [`breeze`](https://github.com/KDE/breeze)

            `bb10bright`, `bb10dark`, `cde`, `cleanlooks`, `gtk2`, `motif`, `plastique`
            : Use styles from
              [`qtstyleplugins`](https://github.com/qt/qtstyleplugins)

            `kvantum`
            : Use styles from
              [`kvantum`](https://github.com/tsujan/Kvantum)
          '';
        };

        package = mkOption {
          type = with types; nullOr (either package (listOf package));
          default = null;
          example = literalExpression "pkgs.adwaita-qt";
          description = ''
            Theme package to be used in Qt5/Qt6 applications.
            Auto-detected from {option}`qt.style.name` if possible.
          '';
        };
      };
    };
  };

  config = let

    # Necessary because home.sessionVariables doesn't support mkIf
    envVars = filterAttrs (n: v: v != null) {
      QT_QPA_PLATFORMTHEME = if cfg.platformTheme == "gtk" then
        "gtk2"
      else if cfg.platformTheme == "qtct" then
        "qt5ct"
      else
        cfg.platformTheme;
      QT_STYLE_OVERRIDE = cfg.style.name;
    };

  in mkIf (cfg.enable && cfg.platformTheme != null) {
    assertions = [{
      assertion = cfg.platformTheme == "gnome" -> cfg.style.name != null
        && cfg.style.package != null;
      message = ''
        `qt.platformTheme` "gnome" must have `qt.style` set to a theme that
        supports both Qt and Gtk, for example "adwaita", "adwaita-dark", or "breeze".
      '';
    }];

    qt.style.package = mkIf (cfg.style.name != null)
      (mkDefault (stylePackages.${toLower cfg.style.name} or null));

    home.sessionVariables = envVars;

    # Apply theming also to apps started by systemd.
    systemd.user.sessionVariables = envVars;

    home.packages = (if cfg.platformTheme == "gnome" then
      [ pkgs.qgnomeplatform ]
    else if cfg.platformTheme == "qtct" then [
      pkgs.libsForQt5.qt5ct
      pkgs.qt6Packages.qt6ct
    ] else if cfg.platformTheme == "kde" then [
      pkgs.libsForQt5.plasma-integration
      pkgs.libsForQt5.systemsettings
    ] else
      [ pkgs.libsForQt5.qtstyleplugins ])
      ++ lib.optionals (cfg.style.package != null)
      (lib.toList cfg.style.package);

    xsession.importedVariables = [ "QT_QPA_PLATFORMTHEME" ]
      ++ lib.optionals (cfg.style.name != null) [ "QT_STYLE_OVERRIDE" ];

    # Enable GTK+ style for Qt4 in Gtk/GNOME.
    # It doesn’t support the platform theme packages.
    home.activation.useGtkThemeInQt4 =
      mkIf (cfg.platformTheme == "gtk" || cfg.platformTheme == "gnome")
      (hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD ${pkgs.crudini}/bin/crudini $VERBOSE_ARG \
          --set "${config.xdg.configHome}/Trolltech.conf" Qt style GTK+
      '');
  };
}
