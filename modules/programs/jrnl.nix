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
with lib;
{
  options.programs.jrnl = {
    enable = mkEnableOption "jrnl";

    package = lib.mkPackageOption pkgs "jrnl" { nullable = true; };

    settings = mkOption {
      type = yamlFormat.type;
      default = { };
      description = ''
        Configuration for the jrnl binary.
        Available configuration options are described in the jrnl documentation:
        <https://jrnl.sh/en/stable/reference-config-file/>.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."jrnl/jrnl.yaml".source = yamlFormat.generate "jrnl.yaml" cfg.settings;
  };

  meta.maintainers = [ lib.maintainers.matthiasbeyer ];
}
