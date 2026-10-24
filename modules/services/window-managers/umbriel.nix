{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.wayland.windowManager.umbriel;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = [
    lib.maintainers.rachitvrma
  ];
  options.wayland.windowManager.umbriel = {
    enable = lib.mkEnableOption "umbriel";

    package = lib.mkPackageOption pkgs "umbriel" {
      nullable = true;
      extraDescription = ''
        Set to `null` to not add any umbriel package to your path.
      '';
    };

    systemd = {
      enable = lib.mkEnableOption "systemd" // {
        default = true;
        description = ''
          Whether to enable install umbriel's systemd units from the {option}`package`,
          that are used by {command}`start-umbriel`
        '';
      };

      # Note: this option is expected to be present by way-display.
      variables = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          Environment variables to be imported in the systemd & D-Bus user
          environment. Not used by umbriel, as {command}`start-umbriel` already
          imports all environment variables.
        '';
      };

    };

    xwaylandSatellitePackage = lib.mkPackageOption pkgs "xwayland-satellite" {
      nullable = true;
      extraDescription = ''
        With `xwayland-satellite` in the {env}`$PATH`, umbriel can automatically
        start XWayland when needed. Set to `null` if you want to disable xwayland.
        See <https://docs.noctalia.dev/umbriel/>
      '';
    };

    portalPackage = lib.mkPackageOption pkgs "xdg-desktop-portal-umbriel" {
      nullable = true;
      extraDescription = ''
        The portal implementation to use with umbriel.
        The portal can be configured using {file}`XDG_CONFIG_HOME/xdg-desktop-portal-umbriel/config.toml`.
        See <https://github.com/noctalia-dev/xdg-desktop-portal-umbriel>.
      '';
    };

    checkConfig = lib.mkOption {
      type = lib.types.bool;
      default = cfg.package != null;
      defaultText = lib.literalExpression "wayland.windowManager.umbriel.package != null";
      description = "If enabled and package is not null, validates the generated config file.";
    };

    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        keybinds = {
          "Mod+Return" = "spawn:kitty";
          "Mod" = "spawn:noctalia msg panel-toggle launcher";
          "Mod+Q" = "window-close";
        };
        appearance = {
          prefer_no_csd = true;
          border_width = 2;
          outer_border_width = 0;
        };
      };
      description = ''
        Configuration added to {file}`XDG_CONFIG_HOME/umbriel/config.toml`.
        See <https://docs.noctalia.dev/umbriel/configuration/> for more options.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "wayland.windowManager.umbriel" pkgs lib.platforms.linux)
      {
        assertion = cfg.systemd.enable -> cfg.package != null;
        message = "wayland.windowManager.umbriel.systemd.enable requires a non-null package";
      }
      {
        assertion = cfg.checkConfig -> cfg.package != null;
        message = "wayland.windowManager.umbriel.checkConfig requires a non-null package";
      }

    ];

    home.packages = lib.concatLists [
      (lib.optional (cfg.package != null) cfg.package)
      (lib.optional (cfg.xwaylandSatellitePackage != null) cfg.xwaylandSatellitePackage)
    ];

    systemd.user.packages = lib.optional cfg.systemd.enable cfg.package;

    xdg.portal = lib.mkIf (cfg.portalPackage != null) {
      enable = true;
      extraPortals = [ cfg.portalPackage ];
      configPackages = lib.optional (cfg.package != null) cfg.package;
    };

    xdg.configFile."umbriel/config.toml" = lib.mkIf (cfg.settings != { }) {
      source =
        let
          configFile = tomlFormat.generate "umbriel-config.toml" cfg.settings;
        in
        if cfg.checkConfig then
          pkgs.runCommand "umbriel-config-checked" { } ''
            ${lib.getExe cfg.package} validate -c ${configFile}
            cp ${configFile} $out
          ''
        else
          configFile;
    };
  };
}
