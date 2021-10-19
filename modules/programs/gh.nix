{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.gh;

  yamlFormat = pkgs.formats.yaml { };

  settingsType = types.submodule {
    freeformType = yamlFormat.type;
    # These options are only here for the mkRenamedOptionModule support
    options = {
      aliases = mkOption {
        type = with types; attrsOf str;
        default = { };
        example = literalExpression ''
          {
            co = "pr checkout";
            pv = "pr view";
          }
        '';
        description = ''
          Aliases that allow you to create nicknames for gh commands.
        '';
      };
      editor = mkOption {
        type = types.str;
        default = "";
        description = ''
          The editor that gh should run when creating issues, pull requests, etc.
          If blank, will refer to environment.
        '';
      };
      git_protocol = mkOption {
        type = types.str;
        default = "https";
        example = "ssh";
        description = ''
          The protocol to use when performing Git operations.
        '';
      };
    };
  };

in {
  meta.maintainers = [ maintainers.gerschtli maintainers.berbiche ];

  imports = (map (x:
    mkRenamedOptionModule [ "programs" "gh" x ] [
      "programs"
      "gh"
      "settings"
      x
    ]) [ "aliases" "editor" ]) ++ [
      (mkRenamedOptionModule [ "programs" "gh" "gitProtocol" ] [
        "programs"
        "gh"
        "settings"
        "git_protocol"
      ])
    ];

  options.programs.gh = {
    enable = mkEnableOption "GitHub CLI tool";

    package = mkOption {
      type = types.package;
      default = pkgs.gh;
      defaultText = literalExpression "pkgs.gh";
      description = "Package providing <command>gh</command>.";
    };

    settings = mkOption {
      type = settingsType;
      default = { };
      description =
        "Configuration written to <filename>$XDG_CONFIG_HOME/gh/config.yml</filename>.";
      example = literalExpression ''
        {
          git_protocol = "ssh";

          prompt = "enabled";

          aliases = {
            co = "pr checkout";
            pv = "pr view";
          };
        };
      '';
    };

    enableGitCredentialHelper =
      mkEnableOption "the gh git credential helper for github.com" // {
        default = true;
      };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."gh/config.yml".source =
      yamlFormat.generate "gh-config.yml" cfg.settings;

    programs.git.extraConfig.credential."https://github.com".helper =
      mkIf cfg.enableGitCredentialHelper
      "${cfg.package}/bin/gh auth git-credential";
  };
}
