{ config, lib, pkgs, moduleName, mainSection, programName, defaultPackage
, examplePackage, mainExecutable, appletExecutable, xdgConfigFilePath
, serviceDocumentation }:

with lib;

let

  cfg = config.services.${moduleName};
  settingsFormat = pkgs.formats.ini { };

in {
  meta = {
    maintainers = with maintainers; [ rycee petabyteboy thiagokokada ];
  };

  imports = let
    mkRenamed = old: new:
      mkRenamedOptionModule ([ "services" moduleName ] ++ old) [
        "services"
        moduleName
        "settings"
        mainSection
        new
      ];
  in [
    (mkRemovedOptionModule [ "services" moduleName "extraOptions" ]
      "All ${programName} configuration is now available through services.${moduleName}.settings instead.")
  ];

  options = {
    enable = mkEnableOption programName;

    brightness = {
      day = mkOption {
        type = with types; nullOr (either str float);
        default = null;
        description = ''
          Screen brightness to apply during the day,
          between <literal>0.1</literal> and <literal>1.0</literal>.
        '';
      };

      night = mkOption {
        type = with types; nullOr (either str float);
        default = null;
        description = ''
          Screen brightness to apply during the night,
          between <literal>0.1</literal> and <literal>1.0</literal>.
        '';
      };
    };

    dawnTime = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "6:00-7:45";
      description = ''
        Set the time interval of dawn manually.
        The times must be specified as HH:MM in 24-hour format.
      '';
    };

    duskTime = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "18:35-20:15";
      description = ''
        Set the time interval of dusk manually.
        The times must be specified as HH:MM in 24-hour format.
      '';
    };

    latitude = mkOption {
      type = with types; nullOr (either str float);
      default = null;
      description = ''
        Your current latitude, between <literal>-90.0</literal> and
        <literal>90.0</literal>. Must be provided along with
        longitude.
      '';
    };

    longitude = mkOption {
      type = with types; nullOr (either str float);
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

    settings = mkOption {
      type = types.submodule { freeformType = settingsFormat.type; };
      default = { };
      example = literalExample ''
        {
          ${mainSection} = {
            adjustment-method = "randr";
          };
          randr = {
            screen = 0;
          };
        };
      '';
      description = ''
        The configuration to pass to ${programName}.
        Available options for ${programName} described in
        <citerefentry>
          <refentrytitle>${moduleName}</refentrytitle>
          <manvolnum>1</manvolnum>
        </citerefentry>.
      '';
    };
  };

  config = {
    assertions = [{
      assertion = (cfg.settings ? ${mainSection}.dawn-time || cfg.settings
        ? ${mainSection}.dusk-time)
        || (cfg.settings.${mainSection}.location-provider) == "geoclue2"
        || ((cfg.settings.${mainSection}.location-provider) == "manual"
          && (cfg.settings ? manual.lat || cfg.settings ? manual.lon));
      message = ''
        In order for ${programName} to know the time of action, you need to set one of
          - services.${moduleName}.provider = "geoclue2" for automatically inferring your location
            (you also need to enable Geoclue2 service separately)
          - services.${moduleName}.longitude and .latitude for specifying your location manually
          - services.${moduleName}.dawnTime and .duskTime for specifying the times manually
      '';
    }];

    services.${moduleName}.settings = {
      ${mainSection} = {
        temp-day = cfg.temperature.day;
        temp-night = cfg.temperature.night;
        brightness-day = mkIf (cfg.brightness.day != null) (toString cfg.brightness.day);
        brightness-night = mkIf (cfg.brightness.day != null) (toString cfg.brightness.night);
        location-provider = cfg.provider;
        dawn-time = mkIf (cfg.dawnTime != null) cfg.dawnTime;
        dusk-time = mkIf (cfg.duskTime != null) cfg.duskTime;
      };
      manual = mkIf (cfg.provider == "manual") {
        lat = mkIf (cfg.latitude != null) (toString cfg.latitude);
        lon = mkIf (cfg.longitude != null) (toString cfg.longitude);
      };
    };

    xdg.configFile.${xdgConfigFilePath}.source =
      settingsFormat.generate xdgConfigFilePath cfg.settings;

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
          command = if cfg.tray then appletExecutable else mainExecutable;
          configFullPath = config.xdg.configHome + "/${xdgConfigFilePath}";
        in "${cfg.package}/bin/${command} -v -c ${configFullPath}";
        RestartSec = 3;
        Restart = "on-failure";
      };
    };
  };
}
