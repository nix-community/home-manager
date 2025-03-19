{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.easyeffects;

  presetOpts = optionalString (cfg.preset != "") "--load-preset ${cfg.preset}";

  jsonFormat = pkgs.formats.json { };

  presetType = let baseType = types.attrsOf jsonFormat.type;
  in baseType // {
    check = v:
      baseType.check v && elem (head (attrNames v)) [ "input" "output" ];
    description = "EasyEffects input or output JSON preset";
  };

  presetOptionType = mkOption {
    type = types.nullOr (types.attrsOf presetType);
    default = { };
    description = ''
      List of presets to import to easyeffects.
      Presets are written to input and output folder in `$XDG_CONFIG_HOME/easyeffects`.
      Top level block (input/output) determines the folder the file is written to.

      See community presets at:
      https://github.com/wwmm/easyeffects/wiki/Community-Presets
    '';
    example = literalExpression ''
      {
        my-preset = {
          input = {
            blocklist = [

            ];
            "plugins_order" = [
              "rnnoise#0"
            ];
            "rnnoise#0" = {
              bypass = false;
              "enable-vad" = false;
              "input-gain" = 0.0;
              "model-path" = "";
              "output-gain" = 0.0;
              release = 20.0;
              "vad-thres" = 50.0;
              wet = 0.0;
            };
          };
        };
      };
    '';
  };
in {
  meta.maintainers = with maintainers; [ fufexan hausken ];

  options.services.easyeffects = {
    enable = mkEnableOption ''
      Easyeffects daemon.
      Note, it is necessary to add
      ```nix
      programs.dconf.enable = true;
      ```
      to your system configuration for the daemon to work correctly'';

    package = mkOption {
      type = types.package;
      default = pkgs.easyeffects;
      defaultText = literalExpression "pkgs.easyeffects";
      description = "The `easyeffects` package to use.";
    };

    preset = mkOption {
      type = types.str;
      default = "";
      description = ''
        Which preset to use when starting easyeffects.
        Will likely need to launch easyeffects to initially create preset.
      '';
    };

    extraPresets = presetOptionType;
  };

  config = mkIf cfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "services.easyeffects" pkgs platforms.linux)
    ];

    # running easyeffects will just attach itself to gapplication service
    # at-spi2-core is to minimize journalctl noise of:
    # "AT-SPI: Error retrieving accessibility bus address: org.freedesktop.DBus.Error.ServiceUnknown: The name org.a11y.Bus was not provided by any .service files"
    home.packages = with pkgs; [ cfg.package at-spi2-core ];

    xdg.configFile = mkIf (cfg.extraPresets != { }) (lib.mapAttrs' (k: v:
      # assuming only one of either input or output block is defined, having both in same file not seem to be supported by the application since it separates it by folder
      let folder = builtins.head (builtins.attrNames v);
      in lib.nameValuePair "easyeffects/${folder}/${k}.json" {
        source = jsonFormat.generate "${folder}-${k}.json" v;
      }) cfg.extraPresets);

    systemd.user.services.easyeffects = {
      Unit = {
        Description = "Easyeffects daemon";
        Requires = [ "dbus.service" ];
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" "pipewire.service" ];
      };

      Install.WantedBy = [ "graphical-session.target" ];

      Service = {
        ExecStart =
          "${cfg.package}/bin/easyeffects --gapplication-service ${presetOpts}";
        ExecStop = "${cfg.package}/bin/easyeffects --quit";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
