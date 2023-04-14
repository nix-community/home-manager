{ config, lib, pkgs, ... }:

let
  cfg = config.services.comodoro;

  args = with cfg; {
    inherit preset;
    protocols = if lib.isList protocols then
      lib.concatStringsSep " " protocols
    else
      protocols;
  };

in {
  meta.maintainers = with lib.hm.maintainers; [ soywod ];

  options.services.comodoro = {
    enable = lib.mkEnableOption "Comodoro server";

    package = lib.mkPackageOption pkgs "comodoro" { };

    environment = lib.mkOption {
      type = with lib.types; attrsOf str;
      default = { };
      example = lib.literalExpression ''
        {
          "PASSWORD_STORE_DIR" = "~/.password-store";
        }
      '';
      description = ''
        Extra environment variables to be exported in the service.
      '';
    };

    preset = lib.mkOption {
      type = lib.types.nonEmptyStr;
      description = ''
        Use configuration from the given preset as defined in the configuration file.
      '';
    };

    protocols = lib.mkOption {
      type = with lib.types; nonEmptyListOf nonEmptyStr;
      description = ''
        Define protocols the server should use to accept requests.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    systemd.user.services.comodoro = {
      Unit = {
        Description = "Comodoro server";
        After = [ "network.target" ];
      };
      Install = { WantedBy = [ "default.target" ]; };
      Service = {
        ExecStart = with args;
          "${cfg.package}/bin/comodoro server start ${preset} ${protocols}";
        ExecSearchPath = "/bin";
        Restart = "always";
        RestartSec = 10;
        Environment =
          lib.mapAttrsToList (key: val: "${key}=${val}") cfg.environment;
      };
    };
  };
}
