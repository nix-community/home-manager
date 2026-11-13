{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.ov;
  yamlFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = [ lib.hm.maintainers.ps1ph3r ];

  options.programs.ov = {
    enable = lib.mkEnableOption "ov, a feature-rich terminal pager";

    package = lib.mkPackageOption pkgs "ov" { nullable = true; };

    settings = lib.mkOption {
      inherit (yamlFormat) type;
      default = { };
      example = lib.literalExpression ''
        {
          Prompt = {
            Normal = {
              Prefix = " ";
            };
          };
          KeyBind = {
            half_page_down = [ "d" ];
            half_page_up = [ "u" ];
          };
        }
      '';
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/ov/config.yaml`.
        See <https://github.com/noborus/ov> for supported options.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."ov/config.yaml" = lib.mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "ov-config.yaml" cfg.settings;
    };
  };
}
