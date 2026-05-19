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
  meta.maintainers = [ lib.maintainers.ckgxrg ];

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

    # Backwards compatibility
    clamping = mkOption {
      type = types.nullOr (
        types.enum [
          "clamp"
          "border"
          "repeat"
        ]
      );
      default = null;
      visible = false;
      description = "Clamping mode for all wallpapers.";
    };

    wallpapers = mkOption {
      type = types.listOf (
        types.submodule {
          imports = [
            (lib.mkRenamedOptionModule [ "wallpaperId" ] [ "wallpaper" ])

            # Not working, workaround below
            #
            # (lib.mkRemovedOptionModule [ "fps" ] ''
            #   Set `services.linux-wallpaperengine.fps` instead.
            # '')
            # (lib.mkRemovedOptionModule [ "audio" ] ''
            #   Set `services.linux-wallpaperengine.audio` instead.
            # '')
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
              description = "Name of a playlist in Wallpaper Engine's `config.json`. Do not set alongside `wallpaper`.";
              example = "My Playlist";
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
              default = cfg.clamping;
              defaultText = lib.literalExpression "config.services.linux-wallpaperengine.clamping";
              description = "Clamping mode for this wallpaper.";
            };

            # Backwards compatibility, workaround
            fps = mkOption {
              type = types.nullOr types.int;
              default = null;
              visible = false;
              description = "Removed, use `services.linux-wallpaperengine.fps`.";
            };

            audio = mkOption {
              type = types.nullOr (types.attrsOf types.anything);
              default = null;
              visible = false;
              description = "Removed, use `services.linux-wallpaperengine.audio`.";
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
      {
        assertion = !(cfg.audio.silent && cfg.audio.volume != null);
        message = ''
          services.linux-wallpaperengine.audio.silent and services.linux-wallpaperengine.audio.volume cannot be set together.

          Definitions:
            services.linux-wallpaperengine.audio.silent defined in ${lib.showFiles options.services.linux-wallpaperengine.audio.silent.files}
            services.linux-wallpaperengine.audio.volume defined in ${lib.showFiles options.services.linux-wallpaperengine.audio.volume.files}
        '';
      }
    ]
    # Backwards compatibility, workaround
    ++ lib.flip lib.concatMap cfg.wallpapers (each: [
      {
        assertion = each.fps == null;
        message = ''
          The option definition `services.linux-wallpaperengine.wallpapers.*.fps' no longer has any effect; please remove it.
          Set `services.linux-wallpaperengine.fps' instead.
        '';
      }
      {
        assertion = each.audio == null;
        message = ''
          The option definition `services.linux-wallpaperengine.wallpapers.*.audio' no longer has any effect; please remove it.
          Set `services.linux-wallpaperengine.audio' instead.
        '';
      }
    ]);

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
