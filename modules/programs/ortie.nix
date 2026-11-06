{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.ortie;
  tomlFormat = pkgs.formats.toml { };

in
{
  meta.maintainers = with lib.maintainers; [ soywod ];

  options.programs.ortie = {
    enable = lib.mkEnableOption "Ortie, a CLI to manage OAuth 2.0 tokens";

    package = lib.mkPackageOption pkgs "ortie" { nullable = true; };

    settings = lib.mkOption {
      type = lib.types.submodule { freeformType = tomlFormat.type; };
      default = { };
      example = lib.literalExpression ''
        {
          accounts.personal = {
            default = true;
            client-id = "1234-abcd.apps.googleusercontent.com";
            client-secret.command = "pass show ortie/personal-client-secret";
            endpoints.authorization = "https://accounts.google.com/o/oauth2/v2/auth";
            endpoints.token = "https://oauth2.googleapis.com/token";
            scopes = [ "https://mail.google.com/" ];
            extras.access_type = "offline";
            auto-refresh = true;
            storage.read.command = [ "pass" "show" "ortie/personal" ];
            storage.write.command = "pass insert -m -f ortie/personal";
          };
        }
      '';
      description = ''
        Ortie configuration.

        Every OAuth 2.0 account is declared as an attribute of `accounts`,
        which is the only section the configuration file accepts. The account
        marked `default` is the one used when `--account <NAME>` is omitted.

        Beware that the generated file lands in the world-readable Nix store,
        so read secrets through a command rather than inlining them: prefer
        `client-secret.command` over `client-secret.raw`.

        See <https://github.com/pimalaya/ortie/blob/master/config.sample.toml>
        for supported values.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."ortie/config.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "ortie-config.toml" cfg.settings;
    };
  };
}
