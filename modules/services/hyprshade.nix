{ config, lib, pkgs, ... }:
with lib;
let
  configFormat = pkgs.formats.toml { };
  shadeType = with types;
    submodule {
      options = {
        name = mkOption {
          type = str;
          example = "color-filter";
          description = ''
            name of the shade
          '';
        };

        default = lib.mkEnableOption ''
          whether to use this shade when no other shade is scheduled
        '';

        startTime = mkOption {
          type = nullOr str;
          default = null;
          example = "19:00:00";
          description = ''
            time to start the shade in 24-hour "hh:mm:ss" format
          '';
        };

        endTime = mkOption {
          type = nullOr str;
          default = null;
          example = "06:00:00";
          description = ''
            time to end the shade in 24-hour "hh:mm:ss" format.

            optional if you have more than one shade with startTime
          '';
        };

        config = mkOption {
          inherit (configFormat) type;
          default = { };
          example = {
            type = "red-green";
            strength = 1.0;
          };
          description = ''
            configuration passed to the shade
          '';
        };
      };
    };
  cfg = config.services.hyprshade;
in {
  meta.maintainers = [ maintainers.svl ];

  options.services.hyprshade = {
    enable = mkEnableOption "hyprshade, Hyprland shade configuration tool ";

    package = mkPackageOption pkgs "hyprshade" { };

    additionalShades = mkOption {
      type = types.attrsOf types.str;
      default = [ ];
      description = ''
        additional shades that you can then use with hyprshade
      '';
    };

    schedule = mkOption {
      type = types.listOf shadeType;

      default = [ ];
      example = [
        {
          name = "vibrance";
          default = true;
        }
        {
          name = "blue-light-filter";
          startTime = "19:00:00";
          endTime = "06:00:00";
        }
        {
          name = "color-filter";
          config = {
            type = "red-green";
            strength = 0.5;
          };
        }
      ];
      description = "";
    };

    extraConfig = mkOption {
      inherit (configFormat) type;
      default = { };
      description = ''
        extra configuration to be added to the hyprshade.toml file
      '';
    };

    systemd.enable = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = ''
        whether to enable the hyprshade systemd service that will apply the
        shade based on the provided schedule.

        if you don't provide the schedule, the service may not work
      '';
    };
  };

  config = mkIf cfg.enable {
    xdg.configFile = {
      "hypr/hyprshade.toml".source = let
        mkShadeConf = conf:
          filterAttrs (_: val: val != null) {
            inherit (conf) name config;
            start_time = conf.startTime or null;
            end_time = conf.endTime or null;
            default = conf.default or false;
          };
        config = { shades = builtins.map mkShadeConf cfg.schedule; };
      in pkgs.callPackage ({ runCommand, remarshal }:
        runCommand "hyprshade.toml" {
          nativeBuildInputs = [ remarshal ];
          value = builtins.toJSON (config // cfg.extraConfig);
          passAsFile = [ "value" ];
          preferLocalBuild = true;
        } ''
          json2toml "$valuePath" "$out"
          # remove quotes around time values e.g. "19:00:00" -> 19:00:00
          sed -i 's/"\(\([[:digit:]]\{2\}:\?\)\{3\}\)"/\1/' "$out"
        '') { };
    } // mapAttrs'
      (name: shade: nameValuePair "hypr/shaders/${name}" { text = shade; })
      cfg.additionalShades;

    systemd.user = mkIf cfg.systemd.enable {

      services.hyprshade = {
        Install.WantedBy = [ "graphical-session.target" ];

        Unit = {
          ConditionEnvironment = "HYPRLAND_INSTANCE_SIGNATURE";
          Description = "Apply screen filter";
          After = [ "graphical-session-pre.target" ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${getExe cfg.package} auto";
        };
      };

      timers.hyprshade = {

        Install.WantedBy = [ "timers.target" ];

        Unit = { Description = "Apply screen filter on schedule"; };

        Timer.OnCalendar = builtins.map (time: "*-*-* ${time}") (builtins.foldl'
          (acc: sched:
            acc ++ (lists.optional (sched.startTime != null) sched.startTime)
            ++ (lists.optional (sched.endTime != null) sched.endTime)) [ ]
          cfg.schedule);
      };
    };
  };
}
