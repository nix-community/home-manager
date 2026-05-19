{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;

  cfg = config.services.linux-wallpaperengine;
in
{
  meta.maintainers = [ lib.hm.maintainers.ckgxrg ];

  options.services.linux-wallpaperengine = {
    enable = lib.mkEnableOption "linux-wallpaperengine, an implementation of Wallpaper Engine functionality";

    package = lib.mkPackageOption pkgs "linux-wallpaperengine" { };

    assetsPath = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to the assets directory.";
      example = "~/.local/share/Steam/steamapps/common/wallpaper_engine/assets";
    };

    audio = {
      silent = mkOption {
        type = types.bool;
        default = false;
        description = "Mutes sound of all wallpapers.";
      };

      volume = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Volume of all wallpapers";
      };

      automute = mkOption {
        type = types.bool;
        default = true;
        description = "Automutes when another app is playing sound.";
      };

      processing = mkOption {
        type = types.bool;
        default = true;
        description = "Enables audio processing for wallpapers.";
      };
    };

    fps = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = "Limits the FPS to the given number.";
    };

    extraOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra arguments to pass to the linux-wallpaperengine command.";
      example = [
        "--no-fullscreen-pause"
        "--disable-particles"
      ];
    };

    wallpapers = mkOption {
      type = types.listOf (
        types.submodule {
          imports = [
            (lib.mkRenamedOptionModule [ "wallpaperId" ] [ "wallpaper" ])
          ];
          options = {
            monitor = mkOption {
              type = types.str;
              description = "Which monitor to display the wallpaper.";
              example = "HDMI-A-1";
            };

            wallpaper = mkOption {
              type = types.nullOr types.str;
              description = "Wallpaper to be used. Can be Steam Workshop ID or path to the background folder. Do not set alongside `playlist`.";
              example = "3527223773";
            };

            playlist = mkOption {
              type = types.nullOr types.str;
              description = "Path to a Wallpaper Engine `config.json` playlist to be used. Do not set alongside `wallpaper`";
              example = "config.json";
            };

            extraOptions = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "Extra arguments to pass to the linux-wallpaperengine command for this wallpaper.";
              example = [
                "--scaling fill"
                "--fps 12"
              ];
            };

            scaling = mkOption {
              type = types.nullOr (
                types.enum [
                  "stretch"
                  "fit"
                  "fill"
                  "default"
                ]
              );
              default = null;
              description = "Scaling mode for this wallpaper.";
            };

            clamp = mkOption {
              type = types.nullOr (
                types.enum [
                  "clamp"
                  "border"
                  "repeat"
                ]
              );
              default = null;
              description = "Clamping mode for this wallpaper.";
            };
          };
        }
      );
      default = [ ];
      description = "Define wallpapers.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.linux-wallpaperengine" pkgs lib.platforms.linux)
    ];
    warnings =
      if
        lib.lists.any (
          each:
          (each.wallpaper != null && each.playlist != null)
          || (each.wallpaper == null && each.playlist == null)
        ) cfg.wallpapers
      then
        [
          "linux-wallpaperengine: Please specify one of `services.linux-wallpaperengine.wallpapers.*.wallpaper` or `services.linux-wallpaperengine.wallpapers.*.playlist`"
        ]
      else
        [ ];

    home.packages = [ cfg.package ];

    systemd.user.services."linux-wallpaperengine" =
      let
        args = lib.lists.forEach cfg.wallpapers (
          each:
          lib.concatStringsSep " " (
            lib.cli.toCommandLineGNU { } {
              screen-root = each.monitor;
              inherit (each) scaling fps;
              inherit (each.audio) silent;
              noautomute = !each.audio.automute;
              no-audio-processing = !each.audio.processing;
            }
            ++ each.extraOptions
            ++ [
              "--bg"
              each.wallpaperId
            ]
          )
        );
      in
      {
        Unit = {
          Description = "Implementation of Wallpaper Engine on Linux";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = lib.concatStringsSep " " (
            [ (lib.getExe cfg.package) ]
            ++ lib.optional (cfg.assetsPath != null) "--assets-dir ${cfg.assetsPath}"
            ++ lib.optional (cfg.clamping != null) "--clamping ${cfg.clamping}"
            ++ args
          );
          Restart = "on-failure";
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
  };
}
