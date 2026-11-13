{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types;

  cfg = config.services.poweralertd;
in
{
  meta.maintainers = [ lib.maintainers.thibautmarty ];

  options.services.poweralertd = {
    enable = lib.mkEnableOption "the Upower-powered power alertd";

    package = lib.mkPackageOption pkgs "poweralertd" { };

    extraArgs = lib.mkOption {
      type = with types; listOf str;
      default = [ ];
      example = [
        "-s"
        "-S"
      ];
      description = ''
        Extra command line arguments to pass to poweralertd.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.poweralertd" pkgs lib.platforms.linux)
    ];

    systemd.user.services.poweralertd = {
      Unit = {
        Description = "UPower-powered power alerter";
        Documentation = "man:poweralertd(1)";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install.WantedBy = [ "graphical-session.target" ];

      Service = {
        Type = "simple";
        ExecStart = "${lib.getExe cfg.package} ${lib.hm.strings.escapeSystemdExecArgs cfg.extraArgs}";
        Restart = "always";
      };
    };
  };
}
