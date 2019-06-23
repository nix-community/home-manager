{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.qt;
  dag = config.lib.dag;

in

{
  meta.maintainers = [ maintainers.rycee ];

  imports = [
    (mkChangedOptionModule
      [ "qt" "useGtkTheme" ]
      [ "qt" "platformTheme" ]
      (config:
        if getAttrFromPath [ "qt" "useGtkTheme" ] config
        then "gtk"
        else null))
  ];

  options = {
    qt = {
      enable = mkEnableOption "Qt 4 and 5 configuration";

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

  config = mkIf (cfg.enable && cfg.platformTheme != null) {
    home.sessionVariables.QT_QPA_PLATFORMTHEME =
      if cfg.platformTheme == "gnome" then "gnome" else "gtk2";

    home.packages =
      if cfg.platformTheme == "gnome"
      then [ pkgs.qgnomeplatform ]
      else [ pkgs.libsForQt5.qtstyleplugins ];

    xsession.importedVariables = [ "QT_QPA_PLATFORMTHEME" ];

    # Enable GTK+ style for Qt4 in either case.
    # It doesn’t support the platform theme packages.
    home.activation.useGtkThemeInQt4 = dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD ${pkgs.crudini}/bin/crudini $VERBOSE_ARG \
        --set "${config.xdg.configHome}/Trolltech.conf" Qt style GTK+
    '';
  };
}
