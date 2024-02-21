{ config, lib, pkgs, ... }:

with lib;

let cfg = config.services.wlsunset;

in {
  meta.maintainers = [ hm.maintainers.matrss ];

  options.services.wlsunset = {
    enable = mkEnableOption "wlsunset";

    package = mkOption {
      type = with types; package;
      default = pkgs.wlsunset;
      defaultText = "pkgs.wlsunset";
      description = ''
        wlsunset derivation to use.
      '';
    };

    latitude = mkOption {
      type = with types; nullOr str;
      example = "-74.3";
      description = ''
        Your current latitude, between `-90.0` and
        `90.0`.
      '';
    };

    longitude = mkOption {
      type = with types; nullOr str;
      example = "12.5";
      description = ''
        Your current longitude, between `-180.0` and
        `180.0`.
      '';
    };

    temperature = {
      day = mkOption {
        type = with types; int;
        default = 6500;
        description = ''
          Colour temperature to use during the day, in Kelvin (K).
          This value must be greater than `temperature.night`.
        '';
      };

      night = mkOption {
        type = with types; int;
        default = 4000;
        description = ''
          Colour temperature to use during the night, in Kelvin (K).
          This value must be smaller than `temperature.day`.
        '';
      };
    };

    gamma = mkOption {
      type = with types; str;
      default = "1.0";
      description = ''
        Gamma value to use.
      '';
    };

    output = mkOption {
      type = with types; nullOr str;
      description = ''
        Name of output to use, by default all outputs are used.
      '';
    };

    time = {
      duration = mkOption {
        type = with types; nullOr int;
        example = 1800;
        description = ''
          The duration in seconds.
        '';
      };

      sunrise = mkOption {
        type = with types; nullOr str;
        example = "06:30";
        description = ''
          The time when the sun rises (in 24 hour format).
        '';
      };

      sunset = mkOption {
        type = with types; nullOr str;
        example = "18:00";
        description = ''
          The time when the sun sets (in 24 hour format).
        '';
      };
    };

    systemdTarget = mkOption {
      type = with types; str;
      default = "graphical-session.target";
      description = ''
        Systemd target to bind to.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.wlsunset" pkgs
        lib.platforms.linux)
    ];

    systemd.user.services.wlsunset = {
      Unit = {
        Description = "Day/night gamma adjustments for Wayland compositors.";
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = let
          args = [
            "-l ${cfg.latitude}"
            "-L ${cfg.longitude}"
            "-t ${toString cfg.temperature.night}"
            "-T ${toString cfg.temperature.day}"
            "-S ${cfg.time.sunrise}"
            "-s ${cfg.time.sunset}"
            "-d ${toString cfg.time.duration}"
            "-g ${cfg.gamma}"
            "-o ${cfg.output}"
          ];
        in "${cfg.package}/bin/wlsunset ${concatStringsSep " " args}";
      };

      Install = { WantedBy = [ cfg.systemdTarget ]; };
    };
  };
}
