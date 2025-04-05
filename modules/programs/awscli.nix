{ config, lib, pkgs, ... }:

let
  cfg = config.programs.awscli;

  iniFormat = pkgs.formats.ini { };

  settingsPath =
    if cfg.settingsPath != ""
    then cfg.settingsPath
    else "${config.home.homeDirectory}/.aws/config";
  credentialsPath =
    if cfg.credentialsPath != ""
    then cfg.credentialsPath
    else "${config.home.homeDirectory}/.aws/credentials";
in {
  meta.maintainers = [ lib.maintainers.anthonyroussel ];

  options.programs.awscli = {
    enable = lib.mkEnableOption "AWS CLI tool";

    package = lib.mkPackageOption pkgs "aws" {
      default = "awscli2";
      nullable = true;
    };

    settingsPath = lib.mkOption {
      type = lib.types.path;
      defaultText = "~/.config/aws/config";
      apply = builtins.toString;
      description = ''
        Absolute path to where the settings file should be placed.
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
      description = "Configuration written to {file}`$HOME/.aws/config`.";
    };

    credentialsPath = lib.mkOption {
      type = lib.types.path;
      defaultText = "~/.config/aws/credentials";
      apply = builtins.toString;
      description = ''
        Absolute path to where the credentials file should be placed.
      '';
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

    home.sessionVariables = mkMerge [
      (lib.mkIf (cfg.settingsPath != "") {
        AWS_CONFIG_FILE = cfg.settingsPath;
      })
      (lib.mkIf (cfg.credentialsPath != "") {
        AWS_SHARED_CREDENTIALS_FILE = cfg.credentialsPath;
      })
    ];

    home.file.${settingsPath} =
      lib.mkIf (cfg.settings != { }) {
        source = iniFormat.generate "aws-config-${config.home.username}"
            cfg.settings;
      };

    home.file.${credentialsPath} =
      lib.mkIf (cfg.credentials != { }) {
        source = iniFormat.generate "aws-credentials-${config.home.username}"
            cfg.credentials;
      };
  };
}
