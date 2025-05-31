{
  options,
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    attrsets
    lists
    literalExpression
    maintainers
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  mergeSets = sets: lists.fold attrsets.recursiveUpdate { } sets;
  cfg = config.services.way-displays;
  yaml = pkgs.formats.yaml { };
in
{
  meta.maintainers = [
    maintainers.jolars
    maintainers.mightyiam
  ];

  options.services.way-displays = {
    enable = mkEnableOption "way-displays";

    package = lib.mkPackageOption pkgs "way-displays" { };

    settings = mkOption {
      type = types.nullOr yaml.type;
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

        When `null` a configuration file is not generated,
        which allows way-displays to write its own configuration.
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

    home.packages = [ cfg.package ];

    wayland.windowManager = lib.mapAttrs (name: _: {
      systemd.variables = [ "XDG_VTNR" ];
    }) options.wayland.windowManager;

    xdg.configFile."way-displays/cfg.yaml" = mkIf (cfg.settings != null) {
      source = yaml.generate "way-displays-config.yaml" (mergeSets [
        {
          CALLBACK_CMD = "${pkgs.libnotify}/bin/notify-send \"way-displays \${CALLBACK_LEVEL}\" \"\${CALLBACK_MSG}\"";
        }
        cfg.settings
      ]);
    };

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
        ExecStart = "${lib.getExe cfg.package}";
        Restart = "always";
      };
    };
  };
}
