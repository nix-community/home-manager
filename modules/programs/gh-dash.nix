{ config, lib, pkgs, ... }:

let

  cfg = config.programs.gh-dash;

  yamlFormat = pkgs.formats.yaml { };

in {
  meta.maintainers = [ lib.maintainers.janik ];

  options.programs.gh-dash = {
    enable = lib.mkEnableOption "GitHub CLI dashboard plugin";

    package = lib.mkPackageOption pkgs "gh-dash" { };

    settings = lib.mkOption {
      type = yamlFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          prSections = [{
            title = "My Pull Requests";
            filters = "is:open author:@me";
          }];
        }
      '';
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/gh-dash/config.yml`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.gh.extensions = [ cfg.package ];

    xdg.configFile."gh-dash/config.yml".source =
      yamlFormat.generate "gh-dash-config.yml" cfg.settings;
  };
}
