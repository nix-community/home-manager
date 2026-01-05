{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.services.pimsync;
in
{
  meta.maintainers = [ lib.maintainers.antonmosich ];

  options.services.pimsync = {
    enable = lib.mkEnableOption "pimsync";

    package = lib.mkPackageOption pkgs "pimsync" { };

    configFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Optional configuration file to use instead of the default file
        ({file}`$XDG_CONFIG_HOME/pimsync/pimsync.conf`).
      '';
    };

    verbosity = lib.mkOption {
      type = lib.types.enum [
        "trace"
        "debug"
        "info"
        "warn"
        "error"
      ];
      description = "The verbosity in which pimsync should log.";
      default = "warn";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.pimsync = {
      Unit = {
        Description = "pimsync calendar and contacts synchronization";
        PartOf = [ "network-online.target" ];
      };
      Install.WantedBy = [ "default.target" ];
      Service = {
        # TODO: make use of the readiness notification
        Type = "simple";

        ExecStart =
          let
            command = [
              (lib.getExe cfg.package)
              "-v"
              cfg.verbosity
            ]
            ++ lib.optionals (cfg.configFile != null) [
              "-c"
              cfg.configFile
            ]
            ++ [ "daemon" ];
          in
          lib.concatStringsSep " " command;
      };
    };
  };
}
