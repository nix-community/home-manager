{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.ashell;
  tomlFormat = pkgs.formats.toml { };
  yamlFormat = pkgs.formats.yaml { };

  packageVersion = if cfg.package != null then lib.getVersion cfg.package else "0.5.0";
  isTomlConfig = lib.versionAtLeast packageVersion "0.5.0";
  settingsFormat = if isTomlConfig then tomlFormat else yamlFormat;
  configFileName = if isTomlConfig then "ashell/config.toml" else "ashell.yml";

  # Create migration function for camelCase to snake_case conversion
  migrateSettings = lib.hm.deprecations.remapAttrsRecursive {
    pred = lib.hm.strings.isCamelCase;
    transform = lib.hm.strings.toSnakeCase;
  };

  # Apply migration only for TOML config (ashell >= 0.5.0)
  processedSettings =
    if isTomlConfig then migrateSettings "programs.ashell.settings" cfg.settings else cfg.settings;
in
{
  meta.maintainers = [ lib.maintainers.justdeeevin ];

  options.programs.ashell = {
    enable = lib.mkEnableOption "ashell, a ready to go wayland status bar for hyprland";

    package = lib.mkPackageOption pkgs "ashell" { nullable = true; };

    settings = lib.mkOption {
      # NOTE: `yaml` type supports null, using `nullOr` for backwards compatibility period
      type = lib.types.nullOr tomlFormat.type;
      default = { };
      example = {
        modules = {
          left = [ "Workspaces" ];
          center = [ "Window Title" ];
          right = [
            "SystemInfo"
            [
              "Clock"
              "Privacy"
              "Settings"
            ]
          ];
        };
        workspaces.visibilityMode = "MonitorSpecific";
      };
      description = ''
        Ashell configuration written to {file}`$XDG_CONFIG_HOME/ashell/config.toml` (0.5.0+)
        or {file}`$XDG_CONFIG_HOME/ashell/config.yaml` (<0.5.0).
        For available settings see
        <https://github.com/MalpenZibo/ashell?tab=readme-ov-file#configuration>.
      '';
    };

    systemd = {
      enable = lib.mkEnableOption "ashell systemd service";

      target = lib.mkOption {
        type = lib.types.str;
        default = config.wayland.systemd.target;
        defaultText = lib.literalExpression "config.wayland.systemd.target";
        example = "hyprland-session.target";
        description = ''
          The systemd target that will automatically start ashell.

          If you set this to a WM-specific target, make sure that systemd
          integration for that WM is enabled (for example,
          [](#opt-wayland.windowManager.hyprland.systemd.enable)). This is
          typically true by default.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          (lib.hm.assertions.assertPlatform "programs.ashell" pkgs lib.platforms.linux)
        ];

        home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];
        xdg.configFile."${configFileName}" = lib.mkIf (cfg.settings != { }) {
          source = settingsFormat.generate "ashell-config" processedSettings;
        };
      }
      (lib.mkIf cfg.systemd.enable {
        systemd.user.services.ashell = {
          Unit = {
            Description = "ashell status bar";
            Documentation = "https://github.com/MalpenZibo/ashell/tree/0.4.1";
            After = [ cfg.systemd.target ];
          };

          Service = {
            ExecStart = "${lib.getExe cfg.package}";
            Restart = "on-failure";
          };

          Install.WantedBy = [ cfg.systemd.target ];
        };
      })
    ]
  );
}
