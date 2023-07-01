{ config, lib, pkgs, ... }:

with lib;

let cfg = config.services.wlsunset;

in {
  meta.maintainers = [ hm.maintainers.matrss ];

  options.services.wlsunset = {
    enable = mkEnableOption "wlsunset";

    package = mkOption {
      type = types.package;
      default = pkgs.wlsunset;
      defaultText = "pkgs.wlsunset";
      description = ''
        wlsunset derivation to use.
      '';
    };

    latitude = mkOption {
      type = types.str;
      description = ''
        Your current latitude, between `-90.0` and
        `90.0`.
      '';
    };

    longitude = mkOption {
      type = types.str;
      description = ''
        Your current longitude, between `-180.0` and
        `180.0`.
      '';
    };

    temperature = {
      day = mkOption {
        type = types.int;
        default = 6500;
        description = ''
          Colour temperature to use during the day, in Kelvin (K).
          This value must be greater than `temperature.night`.
        '';
      };

      night = mkOption {
        type = types.int;
        default = 4000;
        description = ''
          Colour temperature to use during the night, in Kelvin (K).
          This value must be smaller than `temperature.day`.
        '';
      };
    };

    gamma = mkOption {
      type = types.str;
      default = "1.0";
      description = ''
        Gamma value to use.
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
            "-g ${cfg.gamma}"
          ];
        in "${cfg.package}/bin/wlsunset ${concatStringsSep " " args}";
      };

      Install = { WantedBy = [ cfg.systemdTarget ]; };
    };
  };
}
