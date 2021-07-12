{ config, lib, pkgs, ... }:

with lib;

let cfg = config.services.wlsunset;

in {
  meta.maintainers = [ maintainers.matrss ];

  options.services.wlsunset = {
    enable = mkEnableOption "Whether to enable wlsunset.";

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
        Your current latitude, between <literal>-90.0</literal> and
        <literal>90.0</literal>.
      '';
    };

    longitude = mkOption {
      type = types.str;
      description = ''
        Your current longitude, between <literal>-180.0</literal> and
        <literal>180.0</literal>.
      '';
    };

    temperature = {
      day = mkOption {
        type = types.int;
        default = 6500;
        description = ''
          Colour temperature to use during the day, in Kelvin (K).
          This value must be greater than <literal>temperature.night</literal>.
        '';
      };

      night = mkOption {
        type = types.int;
        default = 4000;
        description = ''
          Colour temperature to use during the night, in Kelvin (K).
          This value must be smaller than <literal>temperature.day</literal>.
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
