{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.awww;
in
{
  meta.maintainers = with lib.maintainers; [ hey2022 ];

  imports = (
    map (x: lib.mkRenamedOptionModule [ "services" "swww" x ] [ "services" "awww" x ]) [
      "enable"
      "package"
      "extraArgs"
    ]
  );

  options.services.awww = {
    enable = lib.mkEnableOption "awww, An Answer to your Wayland Wallpaper Woes";
    package = lib.mkPackageOption pkgs "awww" { };
    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "--no-cache"
        "--layer"
        "bottom"
      ];
      description = ''
        Options given to awww-daemon when the service is run.

        See `awww-daemon --help` for more information.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.awww" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services.awww = {
      Install = {
        WantedBy = [ config.wayland.systemd.target ];
      };

      Unit = {
        ConditionEnvironment = "WAYLAND_DISPLAY";
        Description = "awww-daemon";
        After = [ config.wayland.systemd.target ];
        PartOf = [ config.wayland.systemd.target ];
      };

      Service = {
        ExecStart = lib.escapeShellArgs (
          [
            (lib.getExe' cfg.package "${cfg.package.meta.mainProgram}-daemon")
          ]
          ++ cfg.extraArgs
        );
        Environment = [
          "PATH=$PATH:${lib.makeBinPath [ cfg.package ]}"
        ];
        Restart = "always";
        RestartSec = 10;
      };
    };
  };
}
