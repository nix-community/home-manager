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
  };

  config = mkIf cfg.enable {
    xdg.configFile."hypr/hyprpaper.conf" = mkIf (cfg.settings != { }) {
      text = lib.hm.generators.toHyprconf {
        attrs = cfg.settings;
        inherit (cfg) importantPrefixes;
      };
    };

    systemd.user.services.hyprpaper = {
      Install = { WantedBy = [ "graphical-session.target" ]; };

      Unit = {
        ConditionEnvironment = "WAYLAND_DISPLAY";
        Description = "hyprpaper";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
        X-Restart-Triggers =
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
