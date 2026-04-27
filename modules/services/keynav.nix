{
  config,
  lib,
  pkgs,
  ...
}:
let

  cfg = config.services.keynav;

  keynavFormat = pkgs.formats.keyValue { mkKeyValue = k: v: "${k} ${v}"; };

in
{
  options.services.keynav = {
    enable = lib.mkEnableOption "keynav";

    package = lib.mkPackageOption pkgs "keynav" { };

    settings = lib.mkOption {
      inherit (keynavFormat) type;
      default = { };
      description = "Configuration for keynav written to {file}`$XDG_CONFIG_HOME/keynav/keynavrc`. Each attribute name is a key binding and the value is the action. See <https://github.com/jordansissel/keynav/blob/master/keynav.pod> for available bindings and actions.";
      example = {
        "2" = "doubleclick,end";
        "4" = "click 4";
        "5" = "click 5";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.keynav" pkgs lib.platforms.linux)
    ];

    xdg.configFile."keynav/keynavrc" = lib.mkIf (cfg.settings != { }) {
      source = keynavFormat.generate "keynavrc" cfg.settings;
    };

    systemd.user.services.keynav = {
      Unit = {
        Description = "keynav";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
        X-Restart-Triggers = lib.mkIf (cfg.settings != { }) [
          "${config.xdg.configFile."keynav/keynavrc".source}"
        ];
      };

      Service = {
        ExecStart = lib.getExe cfg.package;
        RestartSec = 3;
        Restart = "always";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
