{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.saml2aws;
  iniFormat = pkgs.formats.ini { };
  inherit (lib) mkIf mkOption types;
in
{
  meta.maintainers = [ lib.hm.maintainers.mokrinsky ];

  options.programs.saml2aws = {
    enable = lib.mkEnableOption "saml2aws CLI tool";

    package = lib.mkPackageOption pkgs "saml2aws" {
      default = "saml2aws";
      nullable = true;
    };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption {
      inherit config;
      extraDescription = ''If enabled, this will install autocompletion for bash.'';
    };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption {
      inherit config;
      extraDescription = ''If enabled, this will install autocompletion for zsh.'';
    };

    configLocation = mkOption {
      default = "${config.home.homeDirectory}/.saml2aws";
      defaultText = lib.literalExpression ''"''${config.home.homeDirectory}/.saml2aws"'';
      type = types.str;
      example = lib.literalExpression ''"''${config.home.homeDirectory}/.config/.saml2aws"'';
      description = ''
        Environment variable to specify the location of saml2aws configuration.
      '';
    };

    credentials = mkOption {
      type = types.submodule { freeformType = iniFormat.type; };
      default = { };
      example = lib.literalExpression ''
        {
          aws = {
            name = "aws";
            url = "https://domain.tld/uri/of/your/auth/endpoint";
            username = "username";
            provider = "Authentik";
            mfa = "Auto";
            skip_verify = false;
            timeout = 0;
            aws_urn = "urn:amazon:webservices";
            aws_session_duration = 3600;
            aws_profile = "123456789000";
            saml_cache = false;
            disable_remember_device = false;
            disable_sessions = false;
            download_browser_driver = false;
            headless = false;
          };
        }
      '';
      description = ''
        Configuration written to {file}`$HOME/.saml2aws` or config.programs.saml2aws.configLocation.
      '';
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = mkIf (cfg.package != null) [ cfg.package ];

      sessionVariables.SAML2AWS_CONFIGFILE = cfg.configLocation;

      file."${cfg.configLocation}" = mkIf (cfg.credentials != { }) {
        source = iniFormat.generate "saml2aws-credentials-${config.home.username}" cfg.credentials;
      };
    };

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      eval "$(${lib.getExe cfg.package} --completion-script-bash)"
    '';

    programs.zsh.initContent = mkIf cfg.enableZshIntegration ''
      eval "$(${lib.getExe cfg.package} --completion-script-zsh)"
    '';

  };
}
