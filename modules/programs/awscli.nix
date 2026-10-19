{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.awscli;
  iniFormat = pkgs.formats.ini { };

  configFile =
    if config.home.preferXdgDirectories then
      "${config.xdg.configHome}/aws/config"
    else
      "${config.home.homeDirectory}/.aws/config";
  credentialsFile =
    if config.home.preferXdgDirectories then
      "${config.xdg.configHome}/aws/credentials"
    else
      "${config.home.homeDirectory}/.aws/credentials";

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
      description = ''
        Configuration written to
        {file}`$HOME/.aws/config`, or to
        {file}`$XDG_CONFIG_HOME/aws/config` when
        {option}`home.preferXdgDirectories` is enabled. In the latter case, the
        {env}`AWS_CONFIG_FILE` environment variable is exported automatically
        so the AWS CLI reads the same file.

        See <https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html>
        for supported values.
      '';
    };

    credentials = lib.mkOption {
      type = lib.types.submodule { freeformType = iniFormat.type; };
      default = { };
      example = lib.literalExpression ''
        {
          "default" = {
            "credential_process" = "''${pkgs.pass}/bin/pass show aws";
          };
        };
      '';
      description = ''
        Configuration written to
        {file}`$HOME/.aws/credentials`, or to
        {file}`$XDG_CONFIG_HOME/aws/credentials` when
        {option}`home.preferXdgDirectories` is enabled. In the latter case, the
        {env}`AWS_SHARED_CREDENTIALS_FILE` environment variable is exported
        automatically so the AWS CLI reads the same file.

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

    home.file."${configFile}" = lib.mkIf (cfg.settings != { }) {
      source = iniFormat.generate "aws-config-${config.home.username}" cfg.settings;
    };

    home.file."${credentialsFile}" = lib.mkIf (cfg.credentials != { }) {
      source = iniFormat.generate "aws-credentials-${config.home.username}" cfg.credentials;
    };

    home.sessionVariables = lib.mkIf config.home.preferXdgDirectories {
      AWS_CONFIG_FILE = configFile;
      AWS_SHARED_CREDENTIALS_FILE = credentialsFile;
    };
  };
}
