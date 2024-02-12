{ config, osConfig, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf mkOption mkPackageOption types mdDoc;

  cfg = config.services.scrutiny-collector;
in {
  meta.maintainers = [ lib.maintainers.dudeofawesome or "dudeofawesome" ];

  options.services.scrutiny-collector = {
    enable = mkEnableOption (mdDoc "scrutiny-collector");

    package = mkPackageOption pkgs "scrutiny-collector" { };

    config-path = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = mdDoc ''
        Specify the path to the devices file
      '';
    };

    configuration = mkOption {
      type = types.nullOr (pkgs.formats.yaml { }).type;
      default = null;
      description = lib.mdDoc ''
        Specify the configuration for the Scrutiny collector in Nix.
      '';
    };

    api-endpoint = mkOption {
      type = types.str;
      default = "http://localhost:8080";
      description = mdDoc ''
        The api server endpoint
      '';
    };

    log-file = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = mdDoc ''
        Path to file for logging. Leave empty to use STDOUT
      '';
    };

    debug = mkEnableOption "debug logging";

    host-id = mkOption {
      type = types.str;
      default = osConfig.networking.hostName;
      defaultText = lib.literalExpression "config.networking.hostName";
      description = mdDoc ''
        Host identifier/label, used for grouping devices
      '';
    };

    # TODO: this needs to be a list of calendar attrs
    calendar = mkOption {
      type = types.str;
      default = "*-*-* 00:00:00";
      description = mdDoc ''
        Configured when to run the service systemd unit (DayOfWeek Year-Month-Day Hour:Minute:Second).
      '';
    };

    # TODO: is this relevant?
    user = mkOption {
      type = types.str;
      default = "scrutiny-collector";
      description = mdDoc ''
        User under which the scrutiny collector service runs.
      '';
    };

    # TODO: is this relevant?
    group = mkOption {
      type = types.str;
      default = "scrutiny-collector";
      description = mdDoc ''
        Group under which the scrutiny collector service runs.
      '';
    };
  };

  config = mkIf cfg.enable (let
    configFile = if cfg.configuration != null then
      (pkgs.writeTextFile {
        name = "collector.yaml";
        text = (lib.generators.toYAML { } cfg.configuration);
      })
    else
      null;
  in lib.mkMerge [
    { home.packages = [ cfg.package ]; }
    (mkIf pkgs.stdenv.targetPlatform.isDarwin {
      launchd.agents.scrutiny-collector = (let
        args = lib.pipe {
          inherit (cfg) api-endpoint log-file debug host-id;
          config =
            if cfg.config-path != null then cfg.config-path else configFile;
        } [
          (lib.filterAttrs (arg: value: value != null && value != false))
          (lib.mapAttrs' (arg: value: {
            name =
              "${if builtins.stringLength arg > 1 then "--" else "-"}${arg}";
            inherit value;
          }))
          (lib.mapAttrsToList
            (arg: value: [ arg ] ++ (if value != true then [ value ] else [ ])))
          (lib.flatten)
        ];
      in {
        enable = true;
        config = {
          ProgramArguments = [ "${cfg.package}/bin/collector-metrics" "run" ]
            ++ args;

          StartCalendarInterval = [{
            Hour = 0;
            Minute = 0;
          }];
        };
      });
    })
  ]);
}
