{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.piston-cli;
  yamlFormat = pkgs.formats.yaml { };
in {
  meta.maintainers = with maintainers; [ ethancedwards8 ];

  options.programs.piston-cli = {
    enable = mkEnableOption "piston-cli, code runner";

    package = mkOption {
      type = types.package;
      default = pkgs.piston-cli;
      defaultText = literalExpression "pkgs.piston-cli";
      description = "The piston-cli package to use.";
    };

    settings = mkOption {
      type = yamlFormat.type;
      default = { };
      example = literalExpression ''
        {
          theme = "emacs";
          box_style = "MINIMAL_DOUBLE_HEAD";
          prompt_continuation = "...";
          prompt_start = ">>>";
        }
      '';
      description = ''
        Configuration written to
        <filename>$XDG_CONFIG_HOME/piston-cli/config.yml</filename>.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."piston-cli/config.yml" = mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "config.yml" cfg.settings;
    };
  };
}
