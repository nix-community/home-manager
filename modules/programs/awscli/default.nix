{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.awscli;
  iniFormat = pkgs.formats.ini { };

in
{
  meta.maintainers = [ lib.maintainers.anthonyroussel ];

  options.programs.awscli = {
    enable = lib.mkEnableOption "AWS CLI tool";

    package = lib.mkPackageOption pkgs "aws" {
      default = "awscli2";
      nullable = true;
    };

    settings = lib.mkOption {
      type = lib.types.submodule { freeformType = iniFormat.type; };
      default = { };
      example = lib.literalExpression ''
        {
          "default" = {
            region = "eu-west-3";
            output = "json";
          };
        };
      '';
      description = "Configuration written to {file}`$HOME/.aws/config`.";
    };

    credentials = lib.mkOption {
      type = lib.types.submodule { freeformType = iniFormat.type; };
      default = { };
      example = lib.literalExpression ''
        {
          "default" = {
            "credential_process" = "${pkgs.pass}/bin/pass show aws";
          };
        };
      '';
      description = ''
        Configuration written to {file}`$HOME/.aws/credentials`.

        For security reasons, never store cleartext passwords here.
        We recommend that you use `credential_process` option to retrieve
        the IAM credentials from your favorite password manager during runtime,
        or use AWS IAM Identity Center to get short-term credentials.

        See <https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-authentication.html>.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    home.file."${config.home.homeDirectory}/.aws/config" = lib.mkIf (cfg.settings != { }) {
      source = iniFormat.generate "aws-config-${config.home.username}" cfg.settings;
    };

    home.file."${config.home.homeDirectory}/.aws/credentials" = lib.mkIf (cfg.credentials != { }) {
      source = iniFormat.generate "aws-credentials-${config.home.username}" cfg.credentials;
    };
  };
}
