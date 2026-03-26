{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    literalExpression
    mkIf
    mkOption
    mkPackageOption
    mkEnableOption
    ;

  cfg = config.programs.grype;

  yamlFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ dosten ];

  options.programs.grype = {
    enable = mkEnableOption "Grype";
    package = mkPackageOption pkgs "grype" { nullable = true; };
    settings = mkOption {
      inherit (yamlFormat) type;
      default = { };
      defaultText = literalExpression "{ }";
      example = literalExpression ''
        {
          check-for-app-update = false;
        }
      '';
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/grype/config.yaml`.
        See <https://oss.anchore.com/docs/reference/grype/configuration/> for supported values.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."grype/config.yaml" = mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "grype-config" cfg.settings;
    };
  };
}
