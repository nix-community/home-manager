{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) literalExpression mkOption types;

  cfg = config.services.easyeffects;

  presetOpts = lib.optionalString (cfg.preset != "") "--load-preset ${cfg.preset}";

  olderThan8 = lib.versionOlder cfg.package.version "8.0.0"; # This version introduces breaking changes and this check is used to stay backwards compatible

  jsonFormat = pkgs.formats.json { };

  settingType = types.nullOr (
    types.oneOf [
      types.bool
      types.int
      types.float
      types.str
      types.path
    ]
  );

  settingsFile = "${config.xdg.configHome}/easyeffects/db/easyeffectsrc";

  nonEmpty = settings: settings != { };

  hasSettings = lib.any nonEmpty (lib.attrValues cfg.settings);

  settingsOption = "`services.easyeffects.settings`";

  settingsCommands = lib.concatStringsSep "\n" (
    lib.flatten (
      lib.mapAttrsToList (
        group: settings:
        lib.mapAttrsToList (
          key: value:
          let
            formattedValue =
              if value == null then
                "--delete"
              else if builtins.isBool value then
                "--type bool -- ${builtins.toJSON value}"
              else
                "-- ${lib.escapeShellArg (toString value)}";
          in
          "${pkgs.kdePackages.kconfig}/bin/kwriteconfig6"
          + " --file ${lib.escapeShellArg settingsFile}"
          + " --group ${lib.escapeShellArg group}"
          + " --key ${lib.escapeShellArg key}"
          + " ${formattedValue}"
        ) settings
      ) cfg.settings
    )
  );

  settingsScript = pkgs.writeShellScript "easyeffects-settings" ''
    ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg (dirOf settingsFile)}
    ${settingsCommands}
  '';

  presetType =
    let
      baseType = types.attrsOf jsonFormat.type;
    in
    types.addCheck baseType (
      v:
      baseType.check v
      && lib.elem (lib.head (lib.attrNames v)) [
        "input"
        "output"
      ]
    );

  presetOptionType = mkOption {
    type = types.nullOr (types.attrsOf presetType);
    default = { };
    description = ''
      List of presets to import to easyeffects.
      Presets are written to input and output folder in `$XDG_DATA_HOME/easyeffects`.
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
in
{
  meta.maintainers = with lib.maintainers; [
    fufexan
    hausken
  ];

  options.services.easyeffects = {
    enable = lib.mkEnableOption ''
      Easyeffects daemon.
      Note, it is necessary to add
      ```nix
      programs.dconf.enable = true;
      ```
      to your system configuration for the daemon to work correctly'';

    package = lib.mkPackageOption pkgs "easyeffects" { };

    preset = mkOption {
      type = types.str;
      default = "";
      description = ''
        Which preset to use when starting easyeffects.
        Will likely need to launch easyeffects to initially create preset.
      '';
    };

    extraPresets = presetOptionType;

    settings = mkOption {
      type = types.attrsOf (types.attrsOf settingType);
      default = { };
      example = literalExpression ''
        {
          StreamInputs = {
            inputDevice = "alsa_input.usb-example";
            listenToMic = false;
          };
          StreamOutputs.useDefaultOutputDevice = true;
        }
      '';
      description = ''
        Global EasyEffects settings written to its mutable KConfig database.
        Settings are grouped by KConfig section. A value of `null` deletes the
        corresponding key. This option requires EasyEffects 8.0.0 or later.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.easyeffects" pkgs lib.platforms.linux)
      {
        assertion = !hasSettings || !olderThan8;
        message = "${settingsOption} requires EasyEffects 8.0.0 or later.";
      }
    ];

    home.packages = with pkgs; lib.optional olderThan8 at-spi2-core ++ [ cfg.package ]; # Only include if easyeffects version is below 8.0.0

    xdg.dataFile = lib.mkIf (cfg.extraPresets != null && cfg.extraPresets != { }) (
      lib.mapAttrs' (
        k: v:
        # Assuming only one of either input or output block is defined, having both in same file not seem to be supported by the application since it separates it by folder
        let
          folder = builtins.head (builtins.attrNames v);
        in
        lib.nameValuePair "easyeffects/${folder}/${k}.json" {
          source = jsonFormat.generate "${folder}-${k}.json" v;
        }
      ) cfg.extraPresets
    );

    systemd.user.services.easyeffects = {
      Unit = {
        Description = "Easyeffects daemon";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
        X-Restart-Triggers = [ (builtins.hashString "sha256" (builtins.toJSON cfg.settings)) ];
      };

      Install.WantedBy = [ "graphical-session.target" ];

      Service = {
        ExecStart =
          if olderThan8 then
            "${cfg.package}/bin/easyeffects --gapplication-service ${presetOpts}"
          else
            "${cfg.package}/bin/easyeffects --hide-window --service-mode ${presetOpts}";
        ExecStop = "${cfg.package}/bin/easyeffects --quit";
        KillMode = "mixed";
        Restart = "on-failure";
        RestartSec = 5;
        TimeoutStopSec = 10;
      }
      // lib.optionalAttrs hasSettings {
        ExecStartPre = settingsScript;
      }
      // (
        if olderThan8 then
          {
            Type = "dbus";
            BusName = "com.github.wwmm.easyeffects";
          }
        else
          { }
      );
    };
  };
}
