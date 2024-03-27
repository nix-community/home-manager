{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.hyprland-per-window-layout;
  tomlFormat = pkgs.formats.toml { };

  configFile = tomlFormat.generate "options.toml" cfg.settings;
in {
  meta.maintainers = with lib.maintainers; [ azazak123 ];

  options.services.hyprland-per-window-layout = {
    enable = mkEnableOption
      "hyprland-per-window-layout, per window keyboard layout (language) for Hyprland Wayland compositor";

    package = mkPackageOption pkgs "hyprland-per-window-layout" { };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      example = literalExpression ''
        {
          # list of keyboards to operate on
          # use `hyprctl devices -j` to list all keyboards
          keyboards = [
            "lenovo-keyboard"
          ];

          # layout_index => window classes list
          # use `hyprctl clients` to get class names
          default_layouts = [{
            "1" = [
              "org.telegram.desktop"
            ];
          }];
        }
      '';
      description = ''
        Configuration included in `options.toml`.
        For available options see <https://github.com/coffebar/hyprland-per-window-layout/blob/main/configuration.md>
      '';
    };

    systemdTarget = mkOption {
      type = types.str;
      default = "graphical-session.target";
      example = "hyprland-session.target";
      description = ''
        The systemd target that will automatically start the hyprland-per-window-layout service.

        When setting this value to `"hyprland-session.target"`,
        make sure to also enable {option}`wayland.windowManager.hyprland.systemd.enable`,
        otherwise the service may never be started.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.hyprland-per-window-layout"
        pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."hyprland-per-window-layout/options.toml" =
      mkIf (cfg.settings != { }) { source = configFile; };

    systemd.user.services.hyprland-per-window-layout = {
      Unit = {
        Description =
          "Per window keyboard layout (language) for Hyprland Wayland compositor";
        PartOf = [ cfg.systemdTarget ];
        X-Restart-Triggers = mkIf (cfg.settings != { }) "${configFile}";
      };

      Service = {
        Type = "simple";
        Restart = "on-failure";
        Environment = [ "PATH=${pkgs.hyprland}/bin" ];
        ExecStart = "${cfg.package}/bin/hyprland-per-window-layout";
      };

      Install = { WantedBy = [ cfg.systemdTarget ]; };
    };
  };
}
