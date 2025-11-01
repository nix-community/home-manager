{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkOption
    types
    ;

  cfg = config.services.autotiling;

in
{
  meta.maintainers = [ lib.maintainers.swarsel ];

  options.services.autotiling = {
    enable = lib.mkEnableOption "enable autotiling service";
    package = lib.mkPackageOption pkgs "autotiling" { };

    extraArgs = mkOption {
      type = with types; listOf str;
      default = [ ];
      example = [
        "--workspaces"
        "8"
        "9"
      ];
      description = ''
        Extra arguments to pass to autotiling.
      '';
    };

    systemdTarget = mkOption {
      type = types.str;
      default = "graphical-session.target";
      description = ''
        Systemd target to bind to.
      '';
    };

  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.autotiling" pkgs lib.platforms.linux)
    ];

    systemd.user.services.autotiling = {
      Unit = {
        Description = "Split orientation manager";
        PartOf = [ cfg.systemdTarget ];
        After = [ cfg.systemdTarget ];
      };

      Service = {
        Type = "simple";
        Restart = "always";
        ExecStart = "${lib.getExe cfg.package} ${lib.escapeShellArgs cfg.extraArgs}";
      };

      Install = {
        WantedBy = [ cfg.systemdTarget ];
      };
    };
  };
}
