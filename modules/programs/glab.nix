{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.glab;
  yamlFormat = pkgs.formats.yaml { };

in {
  meta.maintainers = [ maintainers.shikanime ];

  options.programs.glab = {
    enable = mkEnableOption "GitLab CLI";

    package = mkOption {
      type = types.package;
      default = pkgs.glab;
      defaultText = literalExpression "pkgs.glab";
      description = "Package providing {command}`glab`.";
    };

    settings = mkOption {
      type = yamlFormat.type;
      default = { };
      description =
        "Configuration written to {file}`$XDG_CONFIG_HOME/glab-cli/config.yml`.";
      example = literalExpression ''
        {
          git_protocol = "ssh";
        };
      '';
    };

    gitCredentialHelper = {
      enable = mkEnableOption "the glab git credential helper" // {
        default = true;
      };

      hosts = mkOption {
        type = types.listOf types.str;
        default = [ "https://gitlab.com" ];
        description =
          "GitLab hosts to enable the glab git credential helper for";
        example = literalExpression ''
          ["https://gitlab.com"]
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."glab-cli/config.yml".source =
      yamlFormat.generate "glab-cli-config.yml" cfg.settings;

    programs.git.extraConfig.credential = mkIf cfg.gitCredentialHelper.enable
      (builtins.listToAttrs (map (host:
        lib.nameValuePair host {
          helper = "${cfg.package}/bin/glab auth git-credential";
        }) cfg.gitCredentialHelper.hosts));
  };
}
