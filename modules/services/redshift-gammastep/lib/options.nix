# Adapted from Nixpkgs.

{ config, lib, moduleName, programName, defaultPackage, examplePackage
, mainExecutable, appletExecutable, serviceDocumentation }:

with lib;

let

  cfg = config.services.${moduleName};

in {
  meta = {
    maintainers = with maintainers; [ rycee petabyteboy thiagokokada ];
  };

  options = {
    enable = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Enable ${programName} to change your screen's colour temperature
        depending on the time of day.
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
      default = defaultPackage;
      defaultText = literalExample examplePackage;
      description = ''
        ${programName} derivation to use.
      '';
    };

    tray = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Start the ${appletExecutable} tray applet.
      '';
    };

    extraOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "-v" "-m randr" ];
      description = ''
        Additional command-line arguments to pass to
        <command>redshift</command>.
      '';
    };
  };

  config = {
    assertions = [{
      assertion = cfg.provider == "manual" -> cfg.latitude != null
        && cfg.longitude != null;
      message = "Must provide services.${moduleName}.latitude and"
        + " services.${moduleName}.latitude when"
        + " services.${moduleName}.provider is set to \"manual\".";
    }];

    systemd.user.services.${moduleName} = {
      Unit = {
        Description = "${programName} colour temperature adjuster";
        Documentation = serviceDocumentation;
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

          command = if cfg.tray then appletExecutable else mainExecutable;
        in "${cfg.package}/bin/${command} ${concatStringsSep " " args}";
        RestartSec = 3;
        Restart = "on-failure";
      };
    };
  };
}
