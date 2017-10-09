{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.dunst;
  toDunstIni = generators.toINI {
    mkKeyValue = key: value:
    let
      value' =
        if isBool value then (if value then "yes" else "no")
        else if isString value then "\"${value}\""
        else toString value;
    in
      "${key}=${value'}";
  };

in

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    services.dunst = {
      enable = mkEnableOption "the dunst notification daemon";

      settings = mkOption {
        type = types.attrsOf types.attrs;
        default = {};
        description = "Configuration written to ~/.config/dunstrc";
        example = literalExample ''
          {
            global = {
              geometry = "300x5-30+50";
              transparency = 10;
              frame_color = "#eceff1";
              font = "Droid Sans 9";
            };

            urgency_normal = {
              background = "#37474f";
              foreground = "#eceff1";
              timeout = 10;
            };
          };
        '';
      };
    };
  };

  config = mkIf cfg.enable (
    mkMerge [
      {
        home.file.".local/share/dbus-1/services/org.knopwob.dunst.service".source =
          "${pkgs.dunst}/share/dbus-1/services/org.knopwob.dunst.service";

        systemd.user.services.dunst = {
          Unit = {
            Description = "Dunst notification daemon";
            After = [ "graphical-session-pre.target" ];
            PartOf = [ "graphical-session.target" ];
          };

          Service = {
            Type = "dbus";
            BusName = "org.freedesktop.Notifications";
            ExecStart = "${pkgs.dunst}/bin/dunst";
          };
        };
      }

      (mkIf (cfg.settings != {}) {
        home.file.".config/dunst/dunstrc".text = toDunstIni cfg.settings;
      })
    ]
  );
}
