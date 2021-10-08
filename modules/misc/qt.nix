{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.qt;

in {
  meta.maintainers = [ maintainers.rycee ];

  imports = [
    (mkChangedOptionModule [ "qt" "useGtkTheme" ] [ "qt" "platformTheme" ]
      (config:
        if getAttrFromPath [ "qt" "useGtkTheme" ] config then "gtk" else null))
  ];

  options = {
    qt = {
      enable = mkEnableOption "Qt 4 and 5 configuration";

      platformTheme = mkOption {
        type = types.nullOr (types.enum [ "gtk" "gnome" ]);
        default = null;
        example = "gnome";
        relatedPackages =
          [ "qgnomeplatform" [ "libsForQt5" "qtstyleplugins" ] ];
        description = ''
          Selects the platform theme to use for Qt applications.</para>
          <para>The options are
          <variablelist>
            <varlistentry>
              <term><literal>gtk</literal></term>
              <listitem><para>Use GTK theme with
                <link xlink:href="https://github.com/qt/qtstyleplugins">qtstyleplugins</link>
              </para></listitem>
            </varlistentry>
            <varlistentry>
              <term><literal>gnome</literal></term>
              <listitem><para>Use GNOME theme with
                <link xlink:href="https://github.com/FedoraQt/QGnomePlatform">qgnomeplatform</link>
              </para></listitem>
            </varlistentry>
          </variablelist>
        '';
      };

      style = {
        name = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "adwaita-dark";
          relatedPackages = [ "adwaita-qt" [ "libsForQt5" "qtstyleplugins" ] ];
          description = ''
            Selects the style to use for Qt5 applications.</para>
            <para>The options are
            <variablelist>
              <varlistentry>
                <term><literal>adwaita</literal></term>
                <term><literal>adwaita-dark</literal></term>
                <listitem><para>Use Adwaita Qt style with
                  <link xlink:href="https://github.com/FedoraQt/adwaita-qt">adwaita</link>
                </para></listitem>
              </varlistentry>
              <varlistentry>
                <term><literal>cleanlooks</literal></term>
                <term><literal>gtk2</literal></term>
                <term><literal>motif</literal></term>
                <term><literal>plastique</literal></term>
                <listitem><para>Use styles from
                  <link xlink:href="https://github.com/qt/qtstyleplugins">qtstyleplugins</link>
                </para></listitem>
              </varlistentry>
            </variablelist>
          '';
        };

        package = mkOption {
          type = types.nullOr types.package;
          default = null;
          example = literalExpression "pkgs.adwaita-qt";
          description = "Theme package to be used in Qt5 applications.";
        };
      };
    };
  };

  config = mkIf (cfg.enable && cfg.platformTheme != null) {
    assertions = [{
      assertion = (cfg.platformTheme == "gnome")
        -> ((cfg.style.name != null) && (cfg.style.package != null));
      message = ''
        `qt.platformTheme` "gnome" must have `qt.style` set to a theme that
        supports both Qt and Gtk, for example "adwaita" or "adwaita-dark".
      '';
    }];

    # Necessary because home.sessionVariables is of types.attrs
    home.sessionVariables = (filterAttrs (n: v: v != null) {
      QT_QPA_PLATFORMTHEME =
        if cfg.platformTheme == "gnome" then "gnome" else "gtk2";
      QT_STYLE_OVERRIDE = cfg.style.name;
    });

    home.packages = if cfg.platformTheme == "gnome" then
      [ pkgs.qgnomeplatform ]
      ++ lib.optionals (cfg.style.package != null) [ cfg.style.package ]
    else
      [ pkgs.libsForQt5.qtstyleplugins ];

    xsession.importedVariables = [ "QT_QPA_PLATFORMTHEME" ]
      ++ lib.optionals (cfg.style != null) [ "QT_STYLE_OVERRIDE" ];

    # Enable GTK+ style for Qt4 in either case.
    # It doesn’t support the platform theme packages.
    home.activation.useGtkThemeInQt4 = hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${pkgs.crudini}/bin/crudini $VERBOSE_ARG \
        --set "${config.xdg.configHome}/Trolltech.conf" Qt style GTK+
    '';
  };
}
