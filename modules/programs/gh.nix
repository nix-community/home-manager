{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    literalExpression
    mkIf
    mkOption
    types
    ;

  cfg = config.programs.gh;

  yamlFormat = pkgs.formats.yaml { };

  settingsType = types.submodule {
    freeformType = yamlFormat.type;
  };

in
{
  meta.maintainers = with lib.maintainers; [
    gerschtli
    berbiche
  ];

  imports =
    lib.mapAttrsToList (name: message: lib.mkRemovedOptionModule [ "programs" "gh" name ] message)
      {
        aliases = "Use `programs.gh.settings.aliases` instead.";
        editor = "Use `programs.gh.settings.editor` instead.";
        gitProtocol = "Use `programs.gh.settings.git_protocol` instead.";
        enableGitCredentialHelper = "Use `programs.gh.gitCredentialHelper.enable` instead.";
      };

  options.programs.gh = {
    enable = lib.mkEnableOption "GitHub CLI tool";

    package = lib.mkPackageOption pkgs "gh" { };

    settings = mkOption {
      type = settingsType;
      default = { };
      description = "Configuration written to {file}`$XDG_CONFIG_HOME/gh/config.yml`.";
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

    gitCredentialHelper = {
      enable = lib.mkEnableOption "the gh git credential helper" // {
        default = true;
      };

      hosts = mkOption {
        type = types.listOf types.str;
        default = [
          "https://github.com"
          "https://gist.github.com"
        ];
        description = "GitHub hosts to enable the gh git credential helper for";
        example = literalExpression ''
          [ "https://github.com" "https://github.example.com" ]
        '';
      };
    };

    extensions = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = ''
        gh extensions, see <https://cli.github.com/manual/gh_extension>.
      '';
      example = literalExpression "[ pkgs.gh-eco ]";
    };

    hosts = mkOption {
      inherit (yamlFormat) type;
      default = { };
      description = "Host-specific configuration written to {file}`$XDG_CONFIG_HOME/gh/hosts.yml`.";
      example."github.com".user = "<your_username>";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile = {
      "gh/config.yml".source = yamlFormat.generate "gh-config.yml" ({ version = "1"; } // cfg.settings);
      "gh/hosts.yml" = mkIf (cfg.hosts != { }) {
        source = yamlFormat.generate "gh-hosts.yml" cfg.hosts;
      };
    };

    # Version 2.40.0+ of `gh` needs to migrate account formats, this needs to
    # happen before the version = 1 is placed in the configuration file. Running
    # `gh help` is sufficient to perform the migration. If the migration already
    # has occurred, then this is a no-op.
    #
    # See https://github.com/nix-community/home-manager/issues/4744 for details.
    home.activation.migrateGhAccounts =
      let
        ghHosts = "${config.xdg.configHome}/gh/hosts.yml";
      in
      lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
        if [[ ! -L "${ghHosts}" && -f "${ghHosts}" && $(grep --invert-match --quiet '^version:' ${ghHosts}) ]]; then
          (
            TMP_DIR=$(mktemp -d)
            trap "rm --force --recursive $TMP_DIR" EXIT
            cp "${ghHosts}" $TMP_DIR/
            export GH_CONFIG_DIR=$TMP_DIR
            run --silence ${lib.getExe cfg.package} help
            cp $TMP_DIR/hosts.yml "${ghHosts}"
          )
        fi
      '';

    programs.git.settings.credential = mkIf cfg.gitCredentialHelper.enable (
      builtins.listToAttrs (
        map (
          host:
          lib.nameValuePair host {
            helper = [
              ""
              "${cfg.package}/bin/gh auth git-credential"
            ];
          }
        ) cfg.gitCredentialHelper.hosts
      )
    );

    xdg.dataFile."gh/extensions" = mkIf (cfg.extensions != [ ]) {
      source = pkgs.linkFarm "gh-extensions" (
        map (p: {
          name = p.pname;
          path = "${p}/bin";
        }) cfg.extensions
      );
    };
  };
}
