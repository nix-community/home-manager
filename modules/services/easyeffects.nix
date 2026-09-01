{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) literalExpression mkOption types;

  cfg = config.services.easyeffects;

  isSplitPreset = builtins.isAttrs cfg.preset;

  selectedPresets =
    if isSplitPreset then lib.filterAttrs (_: preset: preset != "") cfg.preset else { };

  presetOpts = lib.optionalString (
    !isSplitPreset && cfg.preset != ""
  ) "--load-preset ${lib.escapeShellArg cfg.preset}";

  olderThan8 = lib.versionOlder cfg.package.version "8.0.0"; # This version introduces breaking changes and this check is used to stay backwards compatible

  olderThan8_0_9 = lib.versionOlder cfg.package.version "8.0.9";

  jsonFormat = pkgs.formats.json { };

  splitPresetType = types.submodule {
    options = {
      input = mkOption {
        type = types.str;
        default = "";
        description = "Input preset to load when starting EasyEffects.";
      };

      output = mkOption {
        type = types.str;
        default = "";
        description = "Output preset to load when starting EasyEffects.";
      };
    };
  };

  splitPresetCommands = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      pipeline: preset: "printf '%s\\n' ${lib.escapeShellArg "load_preset:${pipeline}:${preset}"}"
    ) selectedPresets
  );

  loadSplitPresets = pkgs.writeShellScript "easyeffects-load-presets" ''
    preset_socket=$1

    for _ in {1..100}; do
      if [[ -S "$preset_socket" ]]; then
        if {
          :
          ${splitPresetCommands}
        } | ${pkgs.socat}/bin/socat -u -T 1 - UNIX-CONNECT:"$preset_socket"; then
          exit 0
        fi
      fi

      ${pkgs.coreutils}/bin/sleep 0.1
    done

    exit 1
  '';

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
      v != { }
      && lib.all (
        pipeline:
        lib.elem pipeline [
          "input"
          "output"
        ]
      ) (lib.attrNames v)
    );

  presetOptionType = mkOption {
    type = types.nullOr (types.attrsOf presetType);
    default = { };
    description = ''
      List of presets to import to easyeffects.
      Presets are written to input and output folders in `$XDG_DATA_HOME/easyeffects`.
      Each top-level block (`input` or `output`) is written to its corresponding folder.

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
          output = {
            blocklist = [ ];
            "plugins_order" = [ "limiter#0" ];
            "limiter#0" = {
              bypass = false;
              threshold = -1.0;
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
      type = types.either types.str splitPresetType;
      default = "";
      example = literalExpression ''
        {
          input = "voice";
          output = "music";
        }
      '';
      description = ''
        Preset to load when starting EasyEffects.

        A string loads every input or output preset having that name. An
        attribute set selects input and output presets independently and
        requires EasyEffects 8.0.9 or later. An empty string leaves that
        pipeline unchanged.

        You will likely need to launch EasyEffects to initially create presets.
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
      {
        assertion = !isSplitPreset || !olderThan8_0_9;
        message = "Structured `services.easyeffects.preset` requires EasyEffects 8.0.9 or later.";
      }
      {
        assertion = !isSplitPreset || selectedPresets != { };
        message = "Structured `services.easyeffects.preset` must select at least one input or output preset.";
      }
    ];

    home.packages = with pkgs; lib.optional olderThan8 at-spi2-core ++ [ cfg.package ]; # Only include if easyeffects version is below 8.0.0

    xdg.dataFile = lib.mkIf (cfg.extraPresets != null && cfg.extraPresets != { }) (
      lib.concatMapAttrs (
        name: preset:
        lib.mapAttrs' (
          pipeline: settings:
          lib.nameValuePair "easyeffects/${pipeline}/${name}.json" {
            source = jsonFormat.generate "${pipeline}-${name}.json" {
              "${pipeline}" = settings;
            };
          }
        ) preset
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
      // lib.optionalAttrs isSplitPreset {
        ExecStartPost = "-${loadSplitPresets} %t/EasyEffectsServer";
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
