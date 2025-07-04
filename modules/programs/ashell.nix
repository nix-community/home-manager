{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.ashell;
  settingsFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = [ lib.maintainers.justdeeevin ];

  options.programs.ashell = {
    enable = lib.mkEnableOption "ashell, a ready to go wayland status bar for hyprland";

    package = lib.mkPackageOption pkgs "ashell" { nullable = true; };

    settings = lib.mkOption {
      type = settingsFormat.type;
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
        Ashell configuration written to {file}`$XDG_CONFIG_HOME/ashell.yml`.
        For available settings see
        <https://github.com/MalpenZibo/ashell/tree/0.4.1?tab=readme-ov-file#configuration>.
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
        xdg.configFile."ashell.yml" = lib.mkIf (cfg.settings != { }) {
          source = settingsFormat.generate "ashell-config" cfg.settings;
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
