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
      let
        generatedSettings = jsonFormat.generate "readest-settings.json" cfg.settings;
        settingsFile = "${config.xdg.configHome}/com.bilingify.readest/settings.json";
      in
      lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        settings_file=${lib.escapeShellArg settingsFile}
        run mkdir -p "$(dirname "$settings_file")"

        if [[ -f "$settings_file" ]]; then
          verboseEcho "Merging Readest settings"
          temporary_file="$(mktemp)"
          run ${lib.getExe pkgs.jq} -s '.[0] * .[1]' \
            "$settings_file" ${generatedSettings} > "$temporary_file"
          run install -m600 "$temporary_file" "$settings_file"
          rm -f "$temporary_file"
        else
          verboseEcho "Installing initial Readest settings"
          run install -Dm600 ${generatedSettings} "$settings_file"
        fi
      ''
    );
  };
}
