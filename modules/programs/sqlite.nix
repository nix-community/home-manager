{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.programs.sqlite;
  defaultColSeparator = "|";
  defaultPrompt = "sqlite> ";
in
{
  meta.maintainers = [ lib.hm.maintainers.fk29g ];

  options.programs.sqlite = {
    enable = lib.mkEnableOption "sqlite";

    package = lib.mkPackageOption pkgs "sqlite-interactive" {
      nullable = true;
      example = [ "sqlite" ];
    };

    mode = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "ascii"
          "box"
          "column"
          "csv"
          "html"
          "insert"
          "json"
          "line"
          "list"
          "markdown"
          "qbox"
          "quote"
          "table"
          "tabs"
          "tcl"
        ]
      );
      default = null;
      description = ''
        Output format for query results.

        If set to `null`, SQLite uses "list".
      '';
    };

    separator = {
      column = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = " | ";
        description = ''
          Column separator.

          If set to `null`, SQLite uses "${defaultColSeparator}".
        '';
      };

      row = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "\\n\\n";
        description = ''
          Row separator.

          If set to `null`, SQLite uses "\n".
        '';
      };
    };

    prompt = {
      main = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "❯ ";
        description = ''
          Main shell prompt.

          If set to `null`, SQLite uses `${defaultPrompt}`.
        '';
      };

      continue = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Shell prompt for continuing lines of multi-line queries.

          If set to `null`, SQLite uses `   ...> `.
        '';
      };
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Extra lines added to {file}`sqliterc`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."sqlite3/sqliterc".text = lib.concatStringsSep "\n" (
      lib.filter (x: x != "") [
        (lib.optionalString (cfg.mode != null) ".mode ${cfg.mode}")
        (lib.optionalString (
          cfg.separator.column != null && cfg.separator.row != null
        ) ".separator \"${cfg.separator.column}\" \"${cfg.separator.row}\"")
        (lib.optionalString (
          cfg.separator.column != null && cfg.separator.row == null
        ) ".separator \"${cfg.separator.column}\"")
        (lib.optionalString (
          cfg.separator.column == null && cfg.separator.row != null
        ) ".separator \"${defaultColSeparator}\" \"${cfg.separator.row}\"")
        (lib.optionalString (
          cfg.prompt.main != null && cfg.prompt.continue != null
        ) ".prompt \"${cfg.prompt.main}\" \"${cfg.prompt.continue}\"")
        (lib.optionalString (
          cfg.prompt.main != null && cfg.prompt.continue == null
        ) ".prompt \"${cfg.prompt.main}\"")
        (lib.optionalString (
          cfg.prompt.main == null && cfg.prompt.continue != null
        ) ".prompt \"${defaultPrompt}\" \"${cfg.prompt.continue}\"")
        (lib.optionalString (cfg.extraConfig != "") (cfg.extraConfig))
      ]
    );
  };
}
