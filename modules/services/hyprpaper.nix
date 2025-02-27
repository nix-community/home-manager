{ config, lib, pkgs, ... }:
let cfg = config.services.hyprpaper;
in {
  meta.maintainers = with lib.maintainers; [ khaneliman fufexan ];

  options.services.hyprpaper = {
    enable = lib.mkEnableOption "Hyprpaper, Hyprland's wallpaper daemon";

    package = lib.mkPackageOption pkgs "hyprpaper" { };

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

  config = lib.mkIf cfg.enable {
    xdg.configFile."hypr/hyprpaper.conf" = lib.mkIf (cfg.settings != { }) {
      text = lib.hm.generators.toHyprconf {
        attrs = cfg.settings;
        inherit (cfg) importantPrefixes;
      };
    };

    systemd.user.services.hyprpaper = {
      Install = { WantedBy = [ config.wayland.systemd.target ]; };

      Unit = {
        ConditionEnvironment = "WAYLAND_DISPLAY";
        Description = "hyprpaper";
        After = [ config.wayland.systemd.target ];
        PartOf = [ config.wayland.systemd.target ];
        X-Restart-Triggers = lib.mkIf (cfg.settings != { })
          [ "${config.xdg.configFile."hypr/hyprpaper.conf".source}" ];
      };

      Service = {
        ExecStart = "${lib.getExe cfg.package}";
        Restart = "always";
        RestartSec = "10";
      };
    };
  };
}
