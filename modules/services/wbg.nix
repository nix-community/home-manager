{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    getExe
    escapeShellArgs
    mkPackageOption
    types
    ;

  cfg = config.services.wbg;
in
{
  meta.maintainers = with lib.maintainers; [ yarn ];

  options.services.wbg = {
    enable = mkEnableOption "wbg, a super simple wallpaper application for Wayland compositors";
    package = mkPackageOption pkgs "wbg" { };

    image = mkOption {
      type = types.either types.path types.str;
      description = "Path to the wallpaper image.";
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "-s" ];
      description = "Extra command-line arguments to pass to wbg.";
    };
  };

  config = mkIf (cfg.enable && pkgs.stdenv.hostPlatform.isLinux) {
    home.packages = [ cfg.package ];

    systemd.user.services.wbg = {
      Unit = {
        ConditionEnvironment = "WAYLAND_DISPLAY";
        Description = "wbg";
        After = [ config.wayland.systemd.target ];
        PartOf = [ config.wayland.systemd.target ];
      };

      Service = {
        ExecStart = escapeShellArgs ([ (getExe cfg.package) ] ++ cfg.extraArgs ++ [ (toString cfg.image) ]);
        Restart = "on-failure";
        RestartSec = 10;
      };

      Install = {
        WantedBy = [ config.wayland.systemd.target ];
      };
    };
  };
}
