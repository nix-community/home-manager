{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    types
    ;

  cfg = config.programs.dbeaver;
  jsonFormat = pkgs.formats.json { };

  workspaceDir =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/DBeaverData/workspace6"
    else
      "${lib.removePrefix config.home.homeDirectory config.xdg.dataHome}/DBeaverData/workspace6";

  dbeaverConfigDir = "${workspaceDir}/General/.dbeaver";
  dbeaverSettingsDir = "${workspaceDir}/.metadata/.plugins/org.eclipse.core.runtime/.settings";
in
{
  meta.maintainers = with lib.maintainers; [ philocalyst ];

  options.programs.dbeaver = {
    enable = mkEnableOption "DBeaver, a universal database management tool";

    package = mkPackageOption pkgs "dbeaver-bin" {
      nullable = true;
    };

    settings = mkOption {
      type = types.attrsOf (types.attrsOf types.str);
      default = { };
      example = lib.literalExpression ''
        {
          "org.jkiss.dbeaver.core" = {
            "ui.showSystemObjects" = "false";
            "ui.showUtilityObjects" = "false";
          };
          "org.jkiss.dbeaver.model" = {
            "read.expiration.period" = "10000";
          };
        }
      '';

      description = ''
        DBeaver workspace preferences. Each attribute set key corresponds to
        a preferences file name (without the `.prefs` extension) under
        `General/.settings/` in the DBeaver workspace. Each value is a set
        of key-value preference entries.

        Files are generated with an `eclipse.preferences.version=1` header
        as required by the Eclipse platform.

        Common plugin IDs include `org.jkiss.dbeaver.core`,
        `org.jkiss.dbeaver.model`, and `org.jkiss.dbeaver.ui`.

        For examples:
        https://dbeaver.com/docs/dbeaver/Admin-Manage-Preferences/
      '';
    };

    dataSourcesSettings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = lib.literalExpression ''
        {
          folders = { };
          connections = {
            "postgresql-local" = {
              provider = "postgresql";
              driver = "postgres-jdbc";
              name = "Local PostgreSQL";
              save-password = false;
              configuration = {
                host = "localhost";
                port = "5432";
                database = "mydb";
              };
            };
          };
        }
      '';

      description = ''
        Configuration for DBeaver's `data-sources.json`. This file stores
        database connection definitions and is located at
        `General/.dbeaver/data-sources.json` in the DBeaver workspace.

        See the
        [DBeaver documentation](https://dbeaver.com/docs/dbeaver/Admin-Manage-Connections/)
        for available connection options.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    home.file = lib.mkMerge [
      (mkIf (cfg.dataSourcesSettings != { }) {
        "${dbeaverConfigDir}/data-sources.json".source =
          jsonFormat.generate "dbeaver-data-sources" cfg.dataSourcesSettings;
      })

      (lib.mkMerge (
        lib.mapAttrsToList (name: prefs: {
          "${dbeaverSettingsDir}/${name}.prefs".text = lib.generators.toKeyValue {
            mkKeyValue = lib.generators.mkKeyValueDefault { } "=";
            listsAsDuplicateKeys = false;
          } ({ "eclipse.preferences.version" = "1"; } // prefs);
        }) cfg.settings
      ))
    ];
  };
}
