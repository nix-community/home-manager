{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.comodoro;

in
{
  meta.maintainers = with lib.maintainers; [ soywod ];

  imports = [
    (lib.mkRenamedOptionModule [ "services" "comodoro" "preset" ] [ "services" "comodoro" "account" ])
    (lib.mkRenamedOptionModule
      [ "services" "comodoro" "protocols" ]
      [ "services" "comodoro" "transports" ]
    )
  ];

  options.services.comodoro = {
    enable = lib.mkEnableOption "Comodoro server";

    package = lib.mkPackageOption pkgs "comodoro" { };

    environment = lib.mkOption {
      type = with lib.types; attrsOf str;
      default = { };
      example = {
        "PASSWORD_STORE_DIR" = "~/.password-store";
      };
      description = ''
        Extra environment variables to be exported in the service.
      '';
    };

    account = lib.mkOption {
      type = with lib.types; nullOr nonEmptyStr;
      default = null;
      example = "pomodoro";
      description = ''
        Serve the timer of the given account, as named in the `accounts` table
        of the configuration file. When null, the account marked `default` is
        served.
      '';
    };

    transports = lib.mkOption {
      type =
        with lib.types;
        listOf (enum [
          "socket"
          "tcp"
        ]);
      default = [ ];
      example = [
        "socket"
        "tcp"
      ];
      description = ''
        Accept requests on the given transports. Naming both serves the same
        timer over both at once. When empty, the transport the account marks as
        default is served.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    systemd.user.services.comodoro = {
      Unit = {
        Description = "Comodoro timer server";
        After = [ "network.target" ];
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
      Service = {
        ExecStart = lib.concatStringsSep " " (
          [ (lib.getExe cfg.package) ]
          ++ lib.optionals (cfg.account != null) [
            "--account"
            cfg.account
          ]
          ++ [
            "server"
            "start"
          ]
          ++ cfg.transports
        );
        ExecSearchPath = "/bin";
        Restart = "always";
        RestartSec = 10;
        Environment = lib.mapAttrsToList (key: val: "${key}=${val}") cfg.environment;
      };
    };
  };
}
