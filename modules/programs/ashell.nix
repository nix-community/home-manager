{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.ashell;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = [ lib.maintainers.justdeeevin ];

  options.programs.ashell = {
    enable = lib.mkEnableOption "ashell, a ready to go wayland status bar for hyprland";

    package = lib.mkPackageOption pkgs "ashell" { nullable = true; };

    settings = lib.mkOption {
      inherit (tomlFormat) type;
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
        workspaces.visibility_mode = "MonitorSpecific";
      };
      description = ''
        Ashell configuration written to {file}`$XDG_CONFIG_HOME/ashell/config.toml`.
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
          {
            assertion = cfg.package == null || lib.versionAtLeast (lib.getVersion cfg.package) "0.5.0";
            message = "programs.ashell requires ashell 0.5.0 or later. Upgrade programs.ashell.package to a supported version.";
          }
        ];

        home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];
        xdg.configFile."ashell/config.toml" = lib.mkIf (cfg.settings != { }) {
          source = tomlFormat.generate "ashell-config" cfg.settings;
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
