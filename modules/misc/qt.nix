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
          settings. DEPRECATED:
          Use <varname><link linkend="opt-qt.platformTheme">qt.platformTheme</link></varname>
          instead.
        '';
      };

      platformTheme = mkOption {
        type = types.nullOr (types.enum [ "gtk" "gnome" ]);
        default = null;
        example = "gnome";
        relatedPackages = [
          "qgnomeplatform"
          ["libsForQt5" "qtstyleplugins"]
        ];
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
    };
  };

  config = mkIf (cfg.enable && (cfg.useGtkTheme || cfg.platformTheme != null)) {
    assertions = [
      {
        assertion = cfg.platformTheme == null || !cfg.useGtkTheme;
        message = "qt: Only use 'qt.platformTheme' or 'qt.useGtkTheme', not both.";
      }
    ];

    warnings = mkIf cfg.useGtkTheme [
      "'qt.useGtkTheme' is deprecated, use 'qt.platformTheme' instead."
    ];

    home.sessionVariables.QT_QPA_PLATFORMTHEME =
      if cfg.platformTheme == "gnome" then "gnome" else "gtk2";

    home.packages =
      if cfg.platformTheme == "gnome"
      then [ pkgs.qgnomeplatform ]
      else [ pkgs.libsForQt5.qtstyleplugins ];

    xsession.profileExtra =
      "systemctl --user import-environment QT_QPA_PLATFORMTHEME";

    # Enable GTK+ style for Qt4 in either case.
    # It doesn’t support the platform theme packages.
    home.activation.useGtkThemeInQt4 = dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD ${pkgs.crudini}/bin/crudini $VERBOSE_ARG \
        --set "${config.xdg.configHome}/Trolltech.conf" Qt style GTK+
    '';
  };
}
