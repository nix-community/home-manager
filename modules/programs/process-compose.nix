{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.programs.process-compose;
  yamlFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = [ lib.hm.maintainers.bbigras ];
  options.programs.process-compose = {
    enable = lib.mkEnableOption "the process-compose orchestrator";
    package = lib.mkPackageOption pkgs "process-compose" { nullable = true; };
    settings = lib.mkOption {
      type = yamlFormat.type;
      default = { };
      defaultText = lib.literalExpression "{}";
      description = "The process-compose configuration.";
    };
  };
  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."process-compose/settings.yaml" =
      mkIf (cfg.settings != null && cfg.settings != { })
        {
          source = yamlFormat.generate "settings" cfg.settings;
        };
  };
}
