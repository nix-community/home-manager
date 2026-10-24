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
    mkMerge
    mkOption
    mkPackageOption
    ;

  cfg = config.programs.lakectl;
  yamlFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = with lib.maintainers; [ philocalyst ];

  options.programs.lakectl = {
    enable = mkEnableOption "lakectl";

    package = mkPackageOption pkgs "lakectl" { nullable = true; };

    settings = mkOption {
      inherit (yamlFormat) type;
      default = { };
      example = {
        credentials = {
          access_key_id = "AKIAIOSFODNN7EXAMPLE";
          secret_access_key = "secret";
        };
        server.endpoint_url = "http://127.0.0.1:8000";
      };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/lakectl/config.yaml`.

        `lakectl` normally reads {file}`~/.lakectl.yaml`, so this module also sets
        `LAKECTL_CONFIG_FILE` to the XDG path.

        See <https://docs.lakefs.io/latest/reference/cli/#lakectl-configuration>
        for the full list of options.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf (cfg.package != null) {
      home.packages = [ cfg.package ];
    })
    (mkIf (cfg.settings != { }) (mkMerge [
      (mkIf config.home.preferXdgDirectories {
        home.sessionVariables.LAKECTL_CONFIG_FILE = "${config.xdg.configHome}/lakectl/config.yaml";
        xdg.configFile."lakectl/config.yaml".source =
          yamlFormat.generate "lakectl-config.yaml" cfg.settings;
      })
      (mkIf (!config.home.preferXdgDirectories) {
        home.file.".lakectl.yaml".source = yamlFormat.generate "lakectl-config.yaml" cfg.settings;
      })
    ]))
  ]);
}
