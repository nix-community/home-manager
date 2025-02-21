{ config, lib, pkgs, ... }:

let

  cfg = config.programs.earthly;

  yamlFormat = pkgs.formats.yaml { };

in {
  meta.maintainers = [ lib.hm.maintainers.folliehiyuki ];

  options.programs.earthly = {
    enable = lib.mkEnableOption "earthly";

    package = lib.mkPackageOption pkgs "earthly" { };

    settings = lib.mkOption {
      type = yamlFormat.type;
      default = { };
      description = ''
        Configuration written to ~/.earthly/config.yml file.
        See https://docs.earthly.dev/docs/earthly-config for supported values.
      '';
      example = lib.literalExpression ''
        global = {
          disable_analytics = true;
          disable_log_sharing = true;
        };
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file.".earthly/config.yml" = lib.mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "earthly-config" cfg.settings;
    };
  };
}
