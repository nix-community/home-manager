# Adapted from Nixpkgs.

{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.gammastep;

in {
  meta.maintainers = [ maintainers.petabyteboy ];

  options.services.gammastep = {
    enable = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Enable Gammastep to change your screen's colour temperature depending on
        the time of day.
      '';
    };

    latitude = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Your current latitude, between <literal>-90.0</literal> and
        <literal>90.0</literal>. Must be provided along with
        longitude.
      '';
    };

    longitude = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Your current longitude, between <literal>-180.0</literal> and
        <literal>180.0</literal>. Must be provided along with
        latitude.
      '';
    };

    provider = mkOption {
      type = types.enum [ "manual" "geoclue2" ];
      default = "manual";
      description = ''
        The location provider to use for determining your location. If set to
        <literal>manual</literal> you must also provide latitude/longitude.
        If set to <literal>geoclue2</literal>, you must also enable the global
        geoclue2 service.
      '';
    };

    temperature = {
      day = mkOption {
        type = types.int;
        default = 5500;
        description = ''
          Colour temperature to use during the day, between
          <literal>1000</literal> and <literal>25000</literal> K.
        '';
      };

      night = mkOption {
        type = types.int;
        default = 3700;
        description = ''
          Colour temperature to use at night, between
          <literal>1000</literal> and <literal>25000</literal> K.
        '';
      };
    };

    brightness = {
      day = mkOption {
        type = types.str;
        default = "1";
        description = ''
          Screen brightness to apply during the day,
          between <literal>0.1</literal> and <literal>1.0</literal>.
        '';
      };

      night = mkOption {
        type = types.str;
        default = "1";
        description = ''
          Screen brightness to apply during the night,
          between <literal>0.1</literal> and <literal>1.0</literal>.
        '';
      };
    };

    package = mkOption {
      type = types.package;
      default = pkgs.gammastep;
      defaultText = literalExample "pkgs.gammastep";
      description = ''
        gammastep derivation to use.
      '';
    };

    tray = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Start the gammastep-indicator tray applet.
      '';
    };

    extraOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "-v" "-m randr" ];
      description = ''
        Additional command-line arguments to pass to
        <command>gammastep</command>.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = cfg.provider == "manual" -> cfg.latitude != null
        && cfg.longitude != null;
      message = "Must provide services.gammastep.latitude and"
        + " services.gammastep.latitude when"
        + " services.gammastep.provider is set to \"manual\".";
    }];

    systemd.user.services.gammastep = {
      Unit = {
        Description = "Gammastep colour temperature adjuster";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = {
        ExecStart = let
          providerString = if cfg.provider == "manual" then
            "${cfg.latitude}:${cfg.longitude}"
          else
            cfg.provider;

          args = [
            "-l ${providerString}"
            "-t ${toString cfg.temperature.day}:${
              toString cfg.temperature.night
            }"
            "-b ${toString cfg.brightness.day}:${toString cfg.brightness.night}"
          ] ++ cfg.extraOptions;

          command = if cfg.tray then "gammastep-indicator" else "gammastep";
        in "${cfg.package}/bin/${command} ${concatStringsSep " " args}";
        RestartSec = 3;
        Restart = "always";
      };
    };
  };

}
