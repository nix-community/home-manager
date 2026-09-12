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
    optional
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

    stretch = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to stretch the wallpaper to fill the screen.";
    };

    image = mkOption {
      type = types.either types.path types.str;
      description = "Path to the wallpaper image.";
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra command-line arguments to pass to wbg.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    systemd.user.services.wbg = {
      Unit = {
        ConditionEnvironment = "WAYLAND_DISPLAY";
        Description = "wbg";
        After = [ config.wayland.systemd.target ];
        PartOf = [ config.wayland.systemd.target ];
      };

      Service = {
        ExecStart = escapeShellArgs (
          [ (getExe cfg.package) ] ++ optional cfg.stretch "-s" ++ [ (toString cfg.image) ] ++ cfg.extraArgs
        );
        Restart = "on-failure";
        RestartSec = 10;
      };

      Install = {
        WantedBy = [ config.wayland.systemd.target ];
      };
    };
  };
}
