{
  pkgs,
  lib,
  config,
  ...
}:

let
  cfg = config.programs.jrnl;
  yamlFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = [ lib.maintainers.matthiasbeyer ];

  options.programs.jrnl = {
    enable = lib.mkEnableOption "jrnl";

    package = lib.mkPackageOption pkgs "jrnl" { nullable = true; };

    settings = lib.mkOption {
      inherit (yamlFormat) type;
      default = { };
      description = ''
        Configuration for the jrnl binary.
        Available configuration options are described in the jrnl documentation:
        <https://jrnl.sh/en/stable/reference-config-file/>.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."jrnl/jrnl.yaml" = lib.mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "jrnl.yaml" cfg.settings;
    };
  };
}
