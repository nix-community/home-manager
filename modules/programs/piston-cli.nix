{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.piston-cli;
  yamlFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = with lib.maintainers; [ ethancedwards8 ];

  options.programs.piston-cli = {
    enable = lib.mkEnableOption "piston-cli, code runner";

    package = lib.mkPackageOption pkgs "piston-cli" { };

    settings = lib.mkOption {
      type = yamlFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          theme = "emacs";
          box_style = "MINIMAL_DOUBLE_HEAD";
          prompt_continuation = "...";
          prompt_start = ">>>";
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/piston-cli/config.yml`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."piston-cli/config.yml" = lib.mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "config.yml" cfg.settings;
    };
  };
}
