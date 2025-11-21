{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.protonmail-bridge;
in
{
  meta.maintainers = with lib.hm.maintainers; [ epixtm ];

  options.services.protonmail-bridge = {
    enable = lib.mkEnableOption "ProtonMail Bridge";
    package = lib.mkPackageOption pkgs "protonmail-bridge" { };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      example = lib.literalExpression "with pkgs; [ pass gnome-keyring ]";
      description = "List of derivations to place in ProtonMail Bridge's service path.";
    };

    logLevel = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "panic"
          "fatal"
          "error"
          "warn"
          "info"
          "debug"
        ]
      );
      default = null;
      description = ''
        Log level of the ProtonMail Bridge service.

        If set to null, the service uses its default log level.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.protonmail-bridge" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services.protonmail-bridge = {
      Unit = {
        Description = "ProtonMail Bridge";
        After = [ "graphical-session.target" ];
      };

      Service = {
        Environment = lib.mkIf (cfg.extraPackages != [ ]) [ "PATH=${lib.makeBinPath cfg.extraPackages}" ];
        ExecStart =
          "${lib.getExe cfg.package} --noninteractive"
          + lib.optionalString (cfg.logLevel != null) " --log-level ${cfg.logLevel}";
        Restart = "always";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
