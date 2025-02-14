{ config, lib, pkgs, ... }:

let

  cfg = config.programs.yambar;
  yamlFormat = pkgs.formats.yaml { };

in {
  meta.maintainers = [ lib.maintainers.carpinchomug ];

  options.programs.yambar = {
    enable = lib.mkEnableOption "Yambar";

    package = lib.mkPackageOption pkgs "yambar" { };

    settings = lib.mkOption {
      type = yamlFormat.type;
      default = { };
      example = lib.literalExpression ''
        bar = {
          location = "top";
          height = 26;
          background = "00000066";

          right = [
            {
              clock.content = [
                {
                  string.text = "{time}";
                }
              ];
            }
          ];
        };
      '';
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/yambar/config.yml`.
        See {manpage}`yambar(5)` for options.
      '';
    };

    systemd.enable = lib.mkEnableOption "yambar systemd integration";

    systemd.target = lib.mkOption {
      type = lib.types.str;
      default = "graphical-session.target";
      example = "sway-session.target";
      description = ''
        The systemd target that will automatically start the yambar service.

        When setting this value to `"sway-session.target"`,
        make sure to also enable {option}`wayland.windowManager.sway.systemd.enable`,
        otherwise the service may never be started.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.yambar" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."yambar/config.yml" = lib.mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "config.yml" cfg.settings;
    };

    systemd.user.services.yambar = lib.mkIf cfg.systemd.enable {
      Unit = {
        Description = "Modular status panel for X11 and Wayland";
        Documentation = "man:yambar";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session-pre.target" ];
      };

      Service = {
        ExecStart = "${cfg.package}/bin/yambar";
        ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
        Restart = "on-failure";
        RestartSec = 3;
        KillMode = "mixed";
      };

      Install = { WantedBy = [ cfg.systemd.target ]; };
    };
  };
}
