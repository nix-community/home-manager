{ config, lib, pkgs, ... }:
with lib;
let

  cfg = config.services.hyprpaper;
in {
  meta.maintainers = [ maintainers.khaneliman maintainers.fufexan ];

  options.services.hyprpaper = {
    enable = mkEnableOption "Hyprpaper, Hyprland's wallpaper daemon";

    package = mkPackageOption pkgs "hyprpaper" { };

    settings = lib.mkOption {
      type = with lib.types;
        let
          valueType = nullOr (oneOf [
            bool
            int
            float
            str
            path
            (attrsOf valueType)
            (listOf valueType)
          ]) // {
            description = "Hyprpaper configuration value";
          };
        in valueType;
      default = { };
      description = ''
        hyprpaper configuration written in Nix. Entries with the same key
        should be written as lists. Variables' and colors' names should be
        quoted. See <https://wiki.hyprland.org/Hypr-Ecosystem/hyprpaper/> for more examples.
      '';
      example = lib.literalExpression ''
        {
          ipc = "on";
          splash = false;
          splash_offset = 2.0;

          preload =
            [ "/share/wallpapers/buttons.png" "/share/wallpapers/cat_pacman.png" ];

          wallpaper = [
            "DP-3,/share/wallpapers/buttons.png"
            "DP-1,/share/wallpapers/cat_pacman.png"
          ];
        }
      '';
    };

    importantPrefixes = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ "$" ];
      example = [ "$" ];
      description = ''
        List of prefix of attributes to source at the top of the config.
      '';
    };

    systemd.target = mkOption {
      type = types.str;
      default = "graphical-session.target";
      example = "sway-session.target";
      description = ''
        The systemd target that will automatically start the Waybar service.

        When setting this value to `"sway-session.target"`,
        make sure to also enable {option}`wayland.windowManager.sway.systemd.enable`,
        otherwise the service may never be started.
      '';
    };
  };

  config = mkIf cfg.enable {
    xdg.configFile."hypr/hyprpaper.conf" = mkIf (cfg.settings != { }) {
      text = lib.hm.generators.toHyprconf {
        attrs = cfg.settings;
        inherit (cfg) importantPrefixes;
      };
    };

    systemd.user.services.hyprpaper = {
      Install = { WantedBy = [ cfg.systemd.target ]; };

      Unit = {
        ConditionEnvironment = "WAYLAND_DISPLAY";
        Description = "hyprpaper";
        PartOf = [ cfg.systemd.target ];
        After = [ cfg.systemd.target ];
        X-Restart-Triggers = mkIf (cfg.settings != { })
          [ "${config.xdg.configFile."hypr/hyprpaper.conf".source}" ];
      };

      Service = {
        ExecStart = "${getExe cfg.package}";
        Restart = "always";
        RestartSec = "10";
      };
    };
  };
}
