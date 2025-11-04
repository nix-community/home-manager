{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.opkssh;

  yamlFormat = pkgs.formats.yaml { };

in
{
  meta.maintainers = [ lib.maintainers.swarsel ];

  options.programs.opkssh = {
    enable = lib.mkEnableOption "enable the OpenPubkey SSH client";

    package = lib.mkPackageOption pkgs "opkssh" { nullable = true; };

    settings = lib.mkOption {
      inherit (yamlFormat) type;
      default = { };
      example = lib.literalExpression ''
        {
        default_provider = "kanidm";

        providers = [
          {
            alias = "kanidm";
            issuer = "https://idm.example.com/oauth2/openid/opkssh";
            client_id = "opkssh";
            scopes = "openid email profile";
            redirect_uris = [
              "http://localhost:3000/login-callback"
              "http://localhost:10001/login-callback"
              "http://localhost:11110/login-callback"
            ];
          };
        ];
        }
      '';
      description = ''
        Configuration written to {file}`$HOME/.opk/config.yml`.
        See <https://github.com/openpubkey/opkssh/blob/main/docs/config.md#client-config-opkconfigyml>.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    home.file."${config.home.homeDirectory}/.opk/config.yml" = lib.mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "opkssh-config-${config.home.username}.yml" cfg.settings;
    };

  };
}
