{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkPackageOption
    mkOption
    mkIf
    literalExpression
    ;

  cfg = config.programs.kraftkit;
  yamlFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = [ lib.hm.maintainers.folliehiyuki ];

  options.programs.kraftkit = {
    enable = mkEnableOption "kraftkit - CLI to build and use customized unikernel VMs";

    package = mkPackageOption pkgs "kraft" { nullable = true; };

    settings = mkOption {
      type = yamlFormat.type;
      default = { };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/kraftkit/config.yaml`.
      '';
      example = literalExpression ''
        no_prompt = true;
        log = {
          level = "info";
          type = "fancy";
        };
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."kraftkit/config.yaml" = mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "kraftkit-config" cfg.settings;
    };
  };
}
