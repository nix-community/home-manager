{ config, lib, pkgs, ... }:
let
  cfg = config.programs.jqp;

  yamlFormat = pkgs.formats.yaml { };
in {
  options.programs.jqp = {
    enable = lib.mkEnableOption "jqp, jq playground";

    package = lib.mkPackageOption pkgs "jqp" { nullable = true; };

    settings = lib.mkOption {
      type = yamlFormat.type;
      default = { };
      example = {
        theme = {
          name = "monokai";
          chromaStyleOverrides = { kc = "#009900 underline"; };
        };
      };
      description = "Jqp configuration";
    };
  };
  config = lib.mkIf cfg.enable {
    home = {
      packages = lib.mkIf (cfg.package != null) [ cfg.package ];

      file.".jqp.yaml" = lib.mkIf (cfg.settings != { }) {
        source = yamlFormat.generate "jqp-config" cfg.settings;
      };
    };
  };
}
