{ config, lib, pkgs, moduleName, mainSection, programName, defaultPackage
, examplePackage, mainExecutable, appletExecutable, xdgConfigFilePath
, serviceDocumentation }:

with lib;

let

  cfg = config.services.${moduleName};
  settingsFormat = pkgs.formats.ini { };

in {
  meta.maintainers = with maintainers; [ rycee thiagokokada ];

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
    (mkRenamed [ "brightness" "day" ] "brightness-day")
    (mkRenamed [ "brightness" "night" ] "brightness-night")
  ];

  options = let
    strNotFloat = (pattern:
      lib.mkOptionType {
        inherit (lib.types.str) merge;

        check = x: lib.types.str.check x && builtins.match pattern x == null;
        description = "string not matching the pattern ${pattern}";
        descriptionClass = "noun";
        name = "strNotMatching ${lib.strings.escapeNixString pattern}";
      }) "^-?[0-9]+\\.[0-9]+$";
  in {
    enable = mkEnableOption programName;

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
      type = with types; nullOr (either float strNotFloat);
      default = null;
      description = ''
        Your current latitude, between `-90.0` and
        `90.0`. Must be provided along with
        longitude.

        Specifying a string retrieves the latitude using the `"$(<
        "''${config.services.${moduleName}.latitude}")"` command at runtime,
        which is useful for reading the value from a decrypted runtime file.
      '';
    };

    longitude = mkOption {
      type = with types; nullOr (either float strNotFloat);
      default = null;
      description = ''
        Your current longitude, between `-180.0` and
        `180.0`. Must be provided along with
        latitude.

        Specifying a string retrieves the longitude using the `"$(<
        "''${config.services.${moduleName}.longitude}")"` command at runtime,
        which is useful for reading the value from a decrypted runtime file.
      '';
    };

    provider = mkOption {
      type = types.enum [ "manual" "geoclue2" ];
      default = "manual";
      description = ''
        The location provider to use for determining your location. If set to
        `manual` you must also provide latitude/longitude.
        If set to `geoclue2`, you must also enable the global
        geoclue2 service.
      '';
    };

    temperature = {
      day = mkOption {
        type = types.int;
        default = 5500;
        description = ''
          Colour temperature to use during the day, between
          `1000` and `25000` K.
        '';
      };
      night = mkOption {
        type = types.int;
        default = 3700;
        description = ''
          Colour temperature to use at night, between
          `1000` and `25000` K.
        '';
      };
    };

    package = mkOption {
      type = types.package;
      default = defaultPackage;
      defaultText = literalExpression examplePackage;
      description = ''
        ${programName} derivation to use.
      '';
    };

    enableVerboseLogging = mkEnableOption "verbose service logging";

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
      example = literalExpression ''
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
        {manpage}`${moduleName}(1)`.
      '';
    };
  };

  config = {
    assertions = [
      (hm.assertions.assertPlatform "services.${moduleName}" pkgs
        platforms.linux)

      {
        assertion = (cfg.settings ? ${mainSection}.dawn-time || cfg.settings
          ? ${mainSection}.dusk-time)
          || (cfg.settings.${mainSection}.location-provider) == "geoclue2"
          || ((cfg.settings.${mainSection}.location-provider) == "manual"
            && (cfg.latitude != null || cfg.longitude != null));
        message = ''
          In order for ${programName} to know the time of action, you need to set one of
            - services.${moduleName}.provider = "geoclue2" for automatically inferring your location
              (you also need to enable Geoclue2 service separately)
            - services.${moduleName}.longitude and .latitude for specifying your location manually
            - services.${moduleName}.dawnTime and .duskTime for specifying the times manually
        '';
      }
    ];

    services.${moduleName}.settings = {
      ${mainSection} = {
        temp-day = cfg.temperature.day;
        temp-night = cfg.temperature.night;
        location-provider = cfg.provider;
        dawn-time = mkIf (cfg.dawnTime != null) cfg.dawnTime;
        dusk-time = mkIf (cfg.duskTime != null) cfg.duskTime;
      };
    };

    xdg.configFile.${xdgConfigFilePath}.source =
      settingsFormat.generate xdgConfigFilePath cfg.settings;

    home.packages = [ cfg.package ];

    systemd.user.services.${moduleName} = {
      Unit = let
        geoclueAgentService =
          lib.optional (cfg.provider == "geoclue2") "geoclue-agent.service";
      in {
        Description = "${programName} colour temperature adjuster";
        Documentation = serviceDocumentation;
        After = [ "graphical-session-pre.target" ] ++ geoclueAgentService;
        Wants = geoclueAgentService;
        PartOf = [ "graphical-session.target" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = {
        ExecStart = let
          command = if cfg.tray then appletExecutable else mainExecutable;
          configFullPath = config.xdg.configHome + "/${xdgConfigFilePath}";
        in pkgs.writeShellScript moduleName ''
          ${cfg.package}/bin/${command} ${
            cli.toGNUCommandLineShell { } {
              v = cfg.enableVerboseLogging;
              c = configFullPath;
            }
          } ${
            optionalString (cfg.provider == "manual"
              && (cfg.latitude != null || cfg.longitude != null)) ''
                -l "${
                  optionalString (cfg.latitude != null)
                  (if builtins.isFloat cfg.latitude then
                    toString cfg.latitude
                  else
                    ''$(< "${cfg.latitude}")'')
                }:${
                  optionalString (cfg.latitude != null)
                  (if builtins.isFloat cfg.longitude then
                    toString cfg.longitude
                  else
                    ''$(< "${cfg.longitude}")'')
                }"''
          }
        '';
        RestartSec = 3;
        Restart = "on-failure";
      };
    };
  };
}
