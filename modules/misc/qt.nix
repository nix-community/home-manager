{ config, lib, pkgs, ... }:

let
  cfg = config.qt;

  # Map platform names to their packages.
  platformPackages = with pkgs; {
    gnome = [ qgnomeplatform qgnomeplatform-qt6 ];
    adwaita = [ qadwaitadecorations qadwaitadecorations-qt6 ];
    gtk = [ libsForQt5.qtstyleplugins qt6Packages.qt6gtk2 ];
    kde = [ libsForQt5.plasma-integration libsForQt5.systemsettings ];
    lxqt = [ lxqt.lxqt-qtplugin lxqt.lxqt-config ];
    qtct = [ libsForQt5.qt5ct qt6Packages.qt6ct ];
  };

  # Maps style names to their QT_QPA_PLATFORMTHEME, if necessary.
  styleNames = {
    gtk = "gtk2";
    qtct = "qt5ct";
  };

  # Maps known lowercase style names to style packages. Non-exhaustive.
  stylePackages = with pkgs; {
    bb10bright = libsForQt5.qtstyleplugins;
    bb10dark = libsForQt5.qtstyleplugins;
    cleanlooks = libsForQt5.qtstyleplugins;
    gtk2 = [ libsForQt5.qtstyleplugins qt6Packages.qt6gtk2 ];
    motif = libsForQt5.qtstyleplugins;
    cde = libsForQt5.qtstyleplugins;
    plastique = libsForQt5.qtstyleplugins;

    adwaita = [ adwaita-qt adwaita-qt6 ];
    adwaita-dark = [ adwaita-qt adwaita-qt6 ];
    adwaita-highcontrast = [ adwaita-qt adwaita-qt6 ];
    adwaita-highcontrastinverse = [ adwaita-qt adwaita-qt6 ];

    breeze = libsForQt5.breeze-qt5;

    kvantum =
      [ libsForQt5.qtstyleplugin-kvantum qt6Packages.qtstyleplugin-kvantum ];
  };

in {
  meta.maintainers = with lib.maintainers; [ rycee thiagokokada ];

  imports = [
    (lib.mkChangedOptionModule [ "qt" "useGtkTheme" ] [ "qt" "platformTheme" ]
      (config:
        if lib.getAttrFromPath [ "qt" "useGtkTheme" ] config then
          "gtk"
        else
          null))
  ];

  options = {
    qt = {
      enable = lib.mkEnableOption "Qt 5 and 6 configuration";

      platformTheme = let
        newOption = {
          name = lib.mkOption {
            type = with lib.types; nullOr str;
            default = null;
            example = "adwaita";
            relatedPackages = [
              "qgnomeplatform"
              "qgnomeplatform-qt6"
              "qadwaitadecorations"
              "qadwaitadecorations-qt6"
              [ "libsForQt5" "plasma-integration" ]
              [ "libsForQt5" "qt5ct" ]
              [ "libsForQt5" "qtstyleplugins" ]
              [ "libsForQt5" "systemsettings" ]
              [ "lxqt" "lxqt-config" ]
              [ "lxqt" "lxqt-qtplugin" ]
              [ "qt6Packages" "qt6ct" ]
              [ "qt6Packages" "qt6gtk2" ]
            ];
            description = ''
              Platform theme to use for Qt applications.

              Some examples are

              `gtk`
              : Use GTK theme with
                [`qtstyleplugins`](https://github.com/qt/qtstyleplugins)

              `gtk3`
              : Use [GTK3 integration](https://github.com/qt/qtbase/tree/dev/src/plugins/platformthemes/gtk3)
                for file picker dialogs, font and theme configuration

              `adwaita`
              : Use Adwaita theme with
                [`qadwaitadecorations`](https://github.com/FedoraQt/QAdwaitaDecorations)

              `gnome` (deprecated)
              : Use GNOME theme with
                [`qgnomeplatform`](https://github.com/FedoraQt/QGnomePlatform).
                Is no longer maintained so prefer `adwaita`.

              `lxqt`
              : Use LXQt theme style set using the
                [`lxqt-config-appearance`](https://github.com/lxqt/lxqt-config)
                application

              `qtct`
              : Use Qt style set using
                [`qt5ct`](https://github.com/desktop-app/qt5ct)
                and [`qt6ct`](https://github.com/trialuser02/qt6ct)
                applications

              `kde`
              : Use Qt settings from Plasma
            '';
          };
          package = lib.mkOption {
            type = with lib.types; nullOr (either package (listOf package));
            default = null;
            example =
              lib.literalExpression "[pkgs.adwaita-qt pkgs.adwaita-qt6]";
            description = ''
              Theme package to be used in Qt5/Qt6 applications.
              Auto-detected from {option}`qt.platformTheme.name` if possible.
              See its documentation for available options.
            '';
          };
        };
      in lib.mkOption {
        type = with lib.types;
          nullOr
          (either (enum [ "gtk" "gtk3" "gnome" "adwaita" "lxqt" "qtct" "kde" ])
            (lib.types.submodule { options = newOption; }));
        default = null;
        description = ''
          Deprecated. Use {option}`qt.platformTheme.name` instead.
        '';
      };
      style = {
        name = lib.mkOption {
          type = with lib.types; nullOr str;
          default = null;
          example = "adwaita-dark";
          relatedPackages = [
            "adwaita-qt"
            "adwaita-qt6"
            [ "libsForQt5" "breeze-qt5" ]
            [ "libsForQt5" "qtstyleplugin-kvantum" ]
            [ "libsForQt5" "qtstyleplugins" ]
            [ "qt6Packages" "qt6gtk2" ]
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

        package = lib.mkOption {
          type = with lib.types; nullOr (either package (listOf package));
          default = null;
          example = lib.literalExpression "pkgs.adwaita-qt";
          description = ''
            Theme package to be used in Qt5/Qt6 applications.
            Auto-detected from {option}`qt.style.name` if possible.
            See its documentation for available options.
          '';
        };
      };
    };
  };

  config = let
    platformTheme = if (builtins.isString cfg.platformTheme) then {
      option = "qt.platformTheme";
      name = cfg.platformTheme;
      package = null;
    } else if cfg.platformTheme == null then {
      option = null;
      name = null;
      package = null;
    } else {
      option = "qt.platformTheme.name";
      name = cfg.platformTheme.name;
      package = cfg.platformTheme.package;
    };

    # Necessary because home.sessionVariables doesn't support mkIf
    envVars = lib.filterAttrs (n: v: v != null) {
      QT_QPA_PLATFORMTHEME = if (platformTheme.name != null) then
        styleNames.${platformTheme.name} or platformTheme.name
      else
        null;
      QT_STYLE_OVERRIDE = cfg.style.name;
    };

    envVarsExtra = let
      inherit (config.home) profileDirectory;
      qtVersions = with pkgs; [ qt5 qt6 ];
      makeQtPath = prefix:
        lib.concatStringsSep ":"
        (map (qt: "${profileDirectory}/${qt.qtbase.${prefix}}") qtVersions);
    in {
      QT_PLUGIN_PATH = "$QT_PLUGIN_PATH\${QT_PLUGIN_PATH:+:}"
        + (makeQtPath "qtPluginPrefix");
      QML2_IMPORT_PATH = "$QML2_IMPORT_PATH\${QML2_IMPORT_PATH:+:}"
        + (makeQtPath "qtQmlPrefix");
    };

  in lib.mkIf cfg.enable {
    assertions = [{
      assertion = platformTheme.name == "gnome" -> cfg.style.name != null
        && cfg.style.package != null;
      message = ''
        `qt.platformTheme.name` "gnome" must have `qt.style` set to a theme that
        supports both Qt and Gtk, for example "adwaita", "adwaita-dark", or "breeze".
      '';
    }];

    warnings = (lib.lists.optional (platformTheme.option == "qt.platformTheme")
      "The option `qt.platformTheme` has been renamed to `qt.platformTheme.name`.")
      ++ (lib.lists.optional
        (platformTheme.name == "gnome" && platformTheme.package == null)
        "The value `gnome` for option `${platformTheme.option}` is deprecated. Use `adwaita` instead.");

    qt.style.package = lib.mkIf (cfg.style.name != null)
      (lib.mkDefault (stylePackages.${lib.toLower cfg.style.name} or null));

    home = {
      sessionVariables = envVars;
      # home.sessionVariables does not support setting the same environment
      # variable to different values.
      # Since some other modules may set the QT_PLUGIN_PATH or QML2_IMPORT_PATH
      # to their own value, e.g.: fcitx5, we avoid conflicts by setting
      # the values in home.sessionVariablesExtra instead.
      sessionVariablesExtra = ''
        export QT_PLUGIN_PATH=${envVarsExtra.QT_PLUGIN_PATH}
        export QML2_IMPORT_PATH=${envVarsExtra.QML2_IMPORT_PATH}
      '';
    };

    # Apply theming also to apps started by systemd.
    systemd.user.sessionVariables = envVars // envVarsExtra;

    home.packages = (lib.findFirst (x: x != [ ]) [ ] [
      (lib.optionals (platformTheme.package != null)
        (lib.toList platformTheme.package))
      (lib.optionals (platformTheme.name != null)
        platformPackages.${platformTheme.name} or [ ])
    ]) ++ (lib.optionals (cfg.style.package != null)
      (lib.toList cfg.style.package));

    xsession.importedVariables = [ "QT_PLUGIN_PATH" "QML2_IMPORT_PATH" ]
      ++ lib.optionals (platformTheme.name != null) [ "QT_QPA_PLATFORMTHEME" ]
      ++ lib.optionals (cfg.style.name != null) [ "QT_STYLE_OVERRIDE" ];
  };
}
