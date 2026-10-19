{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.awscli;
  iniFormat = pkgs.formats.ini { };

  awsConfigDefault = "${config.home.homeDirectory}/.aws/config";
  awsCredentialsDefault = "${config.home.homeDirectory}/.aws/credentials";
in
{
  meta.maintainers = [ lib.maintainers.anthonyroussel ];

  options.programs.awscli = {
    enable = lib.mkEnableOption "AWS CLI tool";

    package = lib.mkPackageOption pkgs "aws" {
      default = "awscli2";
      nullable = true;
    };

    configFile = lib.mkOption {
      type = lib.types.str;
      default =
        if config.home.preferXdgDirectories then
          "${config.xdg.configHome}/aws/config"
        else
          awsConfigDefault;
      defaultText = lib.literalExpression ''
        if config.home.preferXdgDirectories then
          "''${config.xdg.configHome}/aws/config"
        else
          "''${config.home.homeDirectory}/.aws/config"
      '';
      example = lib.literalExpression ''"''${config.xdg.configHome}/aws/config"'';
      description = ''
        Location of the configuration file. Defaults to
        {file}`~/.aws/config`, matching the upstream {command}`aws` CLI
        default, or to {file}`$XDG_CONFIG_HOME/aws/config` when
        {option}`home.preferXdgDirectories` is enabled. The
        {env}`AWS_CONFIG_FILE` environment variable is exported automatically
        whenever this path differs from the upstream default so the AWS CLI
        reads configuration from the same location.
      '';
    };

    credentialsFile = lib.mkOption {
      type = lib.types.str;
      default =
        if config.home.preferXdgDirectories then
          "${config.xdg.configHome}/aws/credentials"
        else
          awsCredentialsDefault;
      defaultText = lib.literalExpression ''
        if config.home.preferXdgDirectories then
          "''${config.xdg.configHome}/aws/credentials"
        else
          "''${config.home.homeDirectory}/.aws/credentials"
      '';
      example = lib.literalExpression ''"''${config.home.homeDirectory}/dotfiles/aws/credentials"'';
      description = ''
        Location of the credentials file. Defaults to
        {file}`~/.aws/credentials`, matching the upstream {command}`aws` CLI
        default, or to {file}`$XDG_CONFIG_HOME/aws/credentials` when
        {option}`home.preferXdgDirectories` is enabled. The
        {env}`AWS_SHARED_CREDENTIALS_FILE` environment variable is exported
        automatically whenever this path differs from the upstream default so
        the AWS CLI reads credentials from the same location.
      '';
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
        Configuration written to {option}`programs.awscli.configFile`.

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
        Configuration written to {option}`programs.awscli.credentialsFile`.

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

    home.file."${cfg.configFile}" = lib.mkIf (cfg.settings != { }) {
      source = iniFormat.generate "aws-config-${config.home.username}" cfg.settings;
    };

    home.file."${cfg.credentialsFile}" = lib.mkIf (cfg.credentials != { }) {
      source = iniFormat.generate "aws-credentials-${config.home.username}" cfg.credentials;
    };

    home.sessionVariables = lib.mkMerge [
      (lib.mkIf (cfg.configFile != awsConfigDefault) {
        AWS_CONFIG_FILE = cfg.configFile;
      })
      (lib.mkIf (cfg.credentialsFile != awsCredentialsDefault) {
        AWS_SHARED_CREDENTIALS_FILE = cfg.credentialsFile;
      })
    ];
  };
}
