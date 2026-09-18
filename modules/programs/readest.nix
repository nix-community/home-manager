{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.readest;
  jsonFormat = pkgs.formats.json { };

  inherit (lib)
    mkEnableOption
    mkPackageOption
    mkOption
    mkIf
    ;
in
{
  meta.maintainers = [ lib.maintainers.nyxar77 ];
  options.programs.readest = {
    enable = mkEnableOption "Readest";
    package = mkPackageOption pkgs "readest" { nullable = true; };

    settings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        telemetryEnabled = false;
        libraryViewMode = "grid";
        globalViewSettings = {
          theme = "dark";
          defaultFontSize = 18;
          lineHeight = 1.5;
        };
      };
      description = ''
        Readest preferences to merge into
        {file}`$XDG_CONFIG_HOME/com.bilingify.readest/settings.json`.

        Readest owns this file and may add or update values while it is
        running. Values declared here take precedence on Home Manager
        activation, while values not declared here are preserved.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    home.activation.readestSettings = mkIf (cfg.settings != { }) (
      lib.hm.dag.entryAfter [ "linkGeneration" ] (
        lib.hm.generators.mkImpureConfigMerger {
          inherit pkgs;
          format = "json";
          empty = "{}";
          jqOperation = "$dynamic * $static";
          path = "${config.xdg.configHome}/com.bilingify.readest/settings.json";
          staticSettings = jsonFormat.generate "readest-settings.json" cfg.settings;
          mode = "600";
        }
      )
    );
  };
}
