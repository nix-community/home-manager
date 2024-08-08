{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.jqp;
  yamlFormat = pkgs.formats.yaml { };
in {
  options.programs.jqp = {
    enable = mkEnableOption "jqp, jq playground";

    package = mkPackageOption pkgs "jqp" { };

    config = mkOption {
      type = with types; attrsOf (oneOf [ str (attrsOf str) bool ]);
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
  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    home.file = mkIf (cfg.config != { }) {
      ".jqp.yaml".source = yamlFormat.generate "jqp global config" cfg.config;
    };
  };
}
