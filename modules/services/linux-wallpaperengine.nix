{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.linux-wallpaperengine;

in {
  meta.maintainers = [ hm.maintainers.ckgxrg ];

  options.services.linux-wallpaperengine = {
    enable = mkEnableOption
      "linux-wallpaperengine, an implementation of Wallpaper Engine functionality";

    package = mkPackageOption pkgs "linux-wallpaperengine" { };

    assetsPath = mkOption {
      type = types.path;
      description = "Path to the assets directory.";
    };

    clamping = mkOption {
      type = types.nullOr (types.enum [ "clamp" "border" "repeat" ]);
      default = null;
      description = "Clamping mode for all wallpapers.";
    };

    wallpapers = mkOption {
      type = types.listOf (types.submodule {
        options = {
          monitor = mkOption {
            type = types.str;
            description = "Which monitor to display the wallpaper.";
          };

          wallpaperId = mkOption {
            type = types.str;
            description = "Wallpaper ID to be used.";
          };

          extraOptions = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description =
              "Extra arguments to pass to the linux-wallpaperengine command for this wallpaper.";
          };

          scaling = mkOption {
            type =
              types.nullOr (types.enum [ "stretch" "fit" "fill" "default" ]);
            default = null;
            description = "Scaling mode for this wallpaper.";
          };

          fps = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = "Limits the FPS to a given number.";
          };

          audio = {
            silent = mkOption {
              type = types.bool;
              default = false;
              description = "Mutes all sound of the wallpaper.";
            };

            automute = mkOption {
              type = types.bool;
              default = true;
              description = "Automute when another app is playing sound.";
            };

            processing = mkOption {
              type = types.bool;
              default = true;
              description = "Enables audio processing for background.";
            };
          };
        };
      });
      default = [ ];
      description = "Define wallpapers.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.linux-wallpaperengine" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services."linux-wallpaperengine" = let
      args = lists.forEach cfg.wallpapers (each:
        concatStringsSep " " (cli.toGNUCommandLine { } {
          screen-root = each.monitor;
          inherit (each) scaling fps;
          silent = each.audio.silent;
          noautomute = !each.audio.automute;
          no-audio-processing = !each.audio.processing;
        } ++ each.extraOptions)
        # This has to be the last argument in each group
        + " --bg ${each.wallpaperId}");
    in {
      Unit = {
        Description = "Implementation of Wallpaper Engine on Linux";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = getExe cfg.package + " --assets-dir ${cfg.assetsPath} "
          + "--clamping ${cfg.clamping} " + (strings.concatStringsSep " " args);
        Restart = "on-failure";
      };
      Install = { WantedBy = [ "graphical-session.target" ]; };
    };
  };
}
