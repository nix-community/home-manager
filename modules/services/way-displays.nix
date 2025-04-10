{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  mergeSets = sets: lists.fold attrsets.recursiveUpdate { } sets;
  cfg = config.services.way-displays;
  yaml = pkgs.formats.yaml { };
in
{
  meta.maintainers = [ maintainers.jolars ];

  options.services.way-displays = {
    enable = mkEnableOption "" // {
      description = ''
        Whether to enable way-displays.
      '';
    };

    package = mkOption {
      type = types.package;
      default = pkgs.way-displays;
      defaultText = literalExpression "pkgs.way-displays";
      description = ''
        way-displays derivation to use.
      '';
    };

    settings = mkOption {
      type = yaml.type;
      default = { };
      example = literalExpression ''
        {
          ORDER = [
            "DP-2"
            "Monitor Maker ABC123"
            "!^my_regex_here[0-9]+"
            "'!.*$'"
          ];
          SCALING = false;
          MODE = [
            {
              NAME_DESC = "HDMI-A-1";
              WIDTH = 1920;
              HEIGHT = 1080;
              HZ = 60;
            }
          ];
          TRANSFORM = [
            {
              NAME_DESC = "eDP-1"
              TRANSFORM = "FLIPPED-90";
            }
          ];
        };
      '';
      description = ''
        The way-displays configuration written to
        {file}`$XDG_CONFIG_HOME/way-displays/cfg.yml`. See
        <https://github.com/alex-courtis/way-displays/wiki/Configuration> for a
        description of available options.
      '';
    };

    systemdTarget = mkOption {
      type = types.str;
      default = config.wayland.systemd.target;
      defaultText = literalExpression "config.wayland.systemd.target";
      description = ''
        Systemd target to bind to.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.way-displays" pkgs lib.platforms.linux)
    ];

    xdg.configFile."way-displays/cfg.yaml".source =
      yaml.generate "way-displays-config.yaml"
        (mergeSets [
          {
            CALLBACK_CMD = "${pkgs.libnotify}/bin/notify-send \"way-displays \${CALLBACK_LEVEL}\" \"\${CALLBACK_MSG}\"";
          }
          cfg.settings
        ]);

    systemd.user.services.way-displays = {
      Unit = {
        Description = "Display configuration service";
        Documentation = "man:way-displays(1)";
        ConditionEnvironment = "WAYLAND_DISPLAY";
        PartOf = cfg.systemdTarget;
        Requires = cfg.systemdTarget;
        After = cfg.systemdTarget;
      };

      Install = {
        WantedBy = [ cfg.systemdTarget ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/way-displays";
        Restart = "always";
      };
    };
  };
}
