{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.earthly;

  yamlFormat = pkgs.formats.yaml { };

in {
  meta.maintainers = [ hm.maintainers.folliehiyuki ];

  options.programs.earthly = {
    enable = mkEnableOption "earthly";

    package = mkPackageOption pkgs "earthly" { };

    settings = mkOption {
      type = yamlFormat.type;
      default = { };
      description = ''
        Configuration written to ~/.earthly/config.yml file.
        See https://docs.earthly.dev/docs/earthly-config for supported values.
      '';
      example = literalExpression ''
        global = {
          disable_analytics = true;
          disable_log_sharing = true;
        };
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file.".earthly/config.yml" = mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "earthly-config" cfg.settings;
    };
  };
}
