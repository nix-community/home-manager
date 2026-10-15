{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    types
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    mkRenamedOptionModule
    mkRemovedOptionModule
    ;

  cfg = config.programs.dank-material-shell;

  jsonFormat = pkgs.formats.json { };

  hasPluginSettings = lib.any (plugin: plugin.settings != { }) (
    lib.attrValues (lib.filterAttrs (_n: v: v.enable) cfg.plugins)
  );
  pluginSettings = lib.mapAttrs (_name: plugin: { enabled = plugin.enable; } // plugin.settings) (
    lib.filterAttrs (_n: v: v.enable) cfg.plugins
  );

  common = {
    packages = [
      cfg.package
    ]
    ++ lib.optional cfg.enableSystemMonitoring cfg.dgop.package
    ++ lib.optionals cfg.enableVPN [
      pkgs.glib
      pkgs.networkmanager
    ]
    ++ lib.optional cfg.enableDynamicTheming pkgs.matugen
    ++ lib.optional cfg.enableAudioWavelength pkgs.cava
    ++ lib.optional cfg.enableCalendarEvents pkgs.khal;

    plugins = lib.mapAttrs (_name: plugin: {
      source = plugin.src;
    }) (lib.filterAttrs (_n: v: v.enable) cfg.plugins);
  };

  path = [
    "programs"
    "dank-material-shell"
  ];

  builtInRemovedMsg = "This is now built-in in DMS and doesn't need additional dependencies.";

in
{
  meta.maintainers = [ lib.maintainers.artur-sannikov ];

  imports = [
    (mkRenamedOptionModule
      [
        "programs"
        "dankMaterialShell"
      ]
      [
        "programs"
        "dank-material-shell"
      ]
    )

    (mkRemovedOptionModule (path ++ [ "enableBrightnessControl" ]) builtInRemovedMsg)
    (mkRemovedOptionModule (path ++ [ "enableColorPicker" ]) builtInRemovedMsg)
    (mkRemovedOptionModule (path ++ [ "enableClipboard" ]) builtInRemovedMsg)
    (mkRemovedOptionModule (path ++ [ "enableNightMode" ]) "Night mode is now always available")
    (mkRemovedOptionModule (
      path ++ [ "enableSystemSound" ]
    ) "qtmultimedia is now included on dms-shell package.")
    (mkRemovedOptionModule (
      path
      ++ [
        "default"
        "settings"
      ]
    ) "Default settings have been removed and been replaced with programs.dank-material-shell.settings")
    (mkRemovedOptionModule (
      path
      ++ [
        "default"
        "session"
      ]
    ) "Default session has been removed and been replaced with programs.dank-material-shell.session")
    (mkRenamedOptionModule
      [ "programs" "dank-material-shell" "enableSystemd" ]
      [ "programs" "dank-material-shell" "systemd" "enable" ]
    )
  ];

  options.programs.dank-material-shell = {

    enable = mkEnableOption "DankMaterialShell";

    package = mkPackageOption pkgs "dms-shell" { nullable = true; };

    settings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      description = ''
        DankMaterialShell configuration settings as an attribute set, to be written to ~/.config/DankMaterialShell/settings.json.
        Full up-to-date list of available settings can be found at https://raw.githubusercontent.com/AvengeMedia/DankMaterialShell/refs/heads/master/quickshell/Common/settings/SettingsSpec.js.
      '';
    };

    dgop = {
      package = mkPackageOption pkgs "dgop" { };
    };

    enableSystemMonitoring = mkOption {
      type = types.bool;
      default = true;
      description = "Add needed dependencies to use system monitoring widgets";
    };

    enableVPN = mkOption {
      type = types.bool;
      default = true;
      description = "Add needed dependencies to use the VPN widget";
    };

    enableDynamicTheming = mkOption {
      type = types.bool;
      default = true;
      description = "Add needed dependencies to have dynamic theming support";
    };

    enableAudioWavelength = mkOption {
      type = types.bool;
      default = true;
      description = "Add needed dependencies to have audio wavelength support";
    };

    enableCalendarEvents = mkOption {
      type = types.bool;
      default = true;
      description = "Add calendar events support via khal";
    };

    enableClipboardPaste = mkOption {
      type = types.bool;
      default = true;
      description = "Deprecated: paste is built into dms; no extra dependencies needed. Kept as a no-op for compatibility.";
    };

    quickshell = {
      package = mkPackageOption pkgs "quickshell" {
        extraDescription = "(we recommend at least 0.3.0, currently available in nixos-unstable)";
      };
    };

    plugins = lib.mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            enable = lib.mkOption {
              type = types.bool;
              default = true;
              description = "Whether to enable this plugin";
            };
            src = lib.mkOption {
              type = types.either types.package types.path;
              description = "Source of the plugin package or path";
            };
            settings = lib.mkOption {
              inherit (jsonFormat) type;
              default = { };
              description = "Plugin settings as an attribute set";
            };
          };
        }
      );
      default = { };
      description = "DMS Plugins to install and enable";
      example = lib.literalExpression ''
        {
          DockerManager = {
            src = pkgs.fetchFromGitHub {
              owner = "LuckShiba";
              repo = "DmsDockerManager";
              rev = "v1.2.0";
              sha256 = "sha256-VoJCaygWnKpv0s0pqTOmzZnPM922qPDMHk4EPcgVnaU=";
            };
          };
          AnotherPlugin = {
            enable = true;
            src = pkgs.another-plugin;
          };
        }
      '';
    };

    clipboardSettings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      description = "DankMaterialShell clipboard settings as an attribute set, to be written to ~/.config/DankMaterialShell/clsettings.json.";
    };

    session = mkOption {
      inherit (jsonFormat) type;
      default = { };
      description = ''
        DankMaterialShell session settings as an attribute set, to be written to ~/.local/state/DankMaterialShell/session.json.
          Full up-to-date list of available settings can be found at https://raw.githubusercontent.com/AvengeMedia/DankMaterialShell/refs/heads/master/quickshell/Common/settings/SessionSpec.js

      '';
    };

    managePluginSettings = mkOption {
      type = lib.types.bool;
      default = hasPluginSettings;
      defaultText = lib.literalExpression ''
        true if any enabled plugin has non-empty `settings`, otherwise false
      '';
      description = "Whether to manage plugin settings. Automatically enabled if any plugins have settings configured.";
    };

    systemd = {
      enable = lib.mkEnableOption "DankMaterialShell systemd startup";
    };

    systemd.target = mkOption {
      type = lib.types.str;
      default = config.wayland.systemd.target;
      defaultText = lib.literalExpression "config.wayland.systemd.target";
      description = "Systemd target to bind to.";
    };
  };

  config = mkIf cfg.enable {
    programs.quickshell = {
      enable = true;
      inherit (cfg.quickshell) package;
    };

    systemd.user.services.dms = mkIf cfg.systemd.enable {
      Unit = {
        Description = "DankMaterialShell";
        PartOf = [ cfg.systemd.target ];
        After = [ cfg.systemd.target ];
      };

      Service = {
        ExecStart = lib.getExe cfg.package + " run --session";
        Restart = "on-failure";
      };

      Install.WantedBy = [ cfg.systemd.target ];
    };

    xdg.stateFile."DankMaterialShell/session.json" = mkIf (cfg.session != { }) {
      source = jsonFormat.generate "session.json" cfg.session;
    };

    xdg.configFile = {
      "DankMaterialShell/settings.json" = mkIf (cfg.settings != { }) {
        source = jsonFormat.generate "settings.json" cfg.settings;
      };
      "DankMaterialShell/clsettings.json" = mkIf (cfg.clipboardSettings != { }) {
        source = jsonFormat.generate "clsettings.json" cfg.clipboardSettings;
      };
      "DankMaterialShell/plugin_settings.json" = mkIf cfg.managePluginSettings {
        source = jsonFormat.generate "plugin_settings.json" pluginSettings;
      };
    }
    // (lib.mapAttrs' (name: value: {
      name = "DankMaterialShell/plugins/${name}";
      inherit value;
    }) common.plugins);
    warnings =
      lib.optional (!cfg.managePluginSettings && hasPluginSettings)
        "You have disabled managePluginSettings but provided plugin settings. These settings will be ignored.";
    home.packages = common.packages;
  };
}
