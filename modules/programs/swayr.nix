{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.swayr;
  tomlFormat = pkgs.formats.toml { };
  configFile = tomlFormat.generate "config.toml" cfg.settings;
  finalConfig = pkgs.writeText "swayr.toml"
    ((builtins.readFile configFile) + cfg.extraConfig);
in {
  meta.maintainers = [ lib.hm.maintainers."9p4" ];

  options.programs.swayr = {
    enable = mkEnableOption "the swayr service";

    settings = mkOption {
      type = types.nullOr tomlFormat.type;
      default = { };
      example = literalExpression ''
        menu = {
          executable = "${pkgs.wofi}/bin/wofi";
          args = [
            "--show=dmenu"
            "--allow-markup"
            "--allow-images"
            "--insensitive"
            "--cache-file=/dev/null"
            "--parse-search"
            "--height=40%"
            "--prompt={prompt}"
          ];
        };

        format = {
          output_format = "{indent}<b>Output {name}</b>    <span alpha=\"20000\">({id})</span>";
          workspace_format = "{indent}<b>Workspace {name} [{layout}]</b> on output {output_name}    <span alpha=\"20000\">({id})</span>";
          container_format = "{indent}<b>Container [{layout}]</b> <i>{marks}</i> on workspace {workspace_name}    <span alpha=\"20000\">({id})</span>";
          window_format = "img:{app_icon}:text:{indent}<i>{app_name}</i> — {urgency_start}<b>“{title}”</b>{urgency_end} <i>{marks}</i> on workspace {workspace_name} / {output_name}    <span alpha=\"20000\">({id})</span>";
          indent = "    ";
          urgency_start = "<span background=\"darkred\" foreground=\"yellow\">";
          urgency_end = "</span>";
          html_escape = true;
        };

        layout = {
          auto_tile = false;
          auto_tile_min_window_width_per_output_width = [
            [ 800 400 ]
            [ 1024 500 ]
            [ 1280 600 ]
            [ 1400 680 ]
            [ 1440 700 ]
            [ 1600 780 ]
            [ 1680 780 ]
            [ 1920 920 ]
            [ 2048 980 ]
            [ 2560 1000 ]
            [ 3440 1200 ]
            [ 3840 1280 ]
            [ 4096 1400 ]
            [ 4480 1600 ]
            [ 7680 2400 ]
          ];
        };

        focus = {
          lockin_delay = 750;
        };

        misc = {
          seq_inhibit = false;
        };
      '';
      description = ''
        Configuration included in `config.toml`.
        For available options see <https://git.sr.ht/~tsdh/swayr#swayr-configuration>
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Extra configuration lines to append to the swayr
        configuration file.
      '';
    };

    systemd.enable = mkEnableOption "swayr systemd integration";
    systemd.target = mkOption {
      type = types.str;
      default = "graphical-session.target";
      description = ''
        Systemd target to bind to.
      '';
    };

    package = mkOption {
      type = types.package;
      default = pkgs.swayr;
      defaultText = literalExpression "pkgs.swayr";
      description = "swayr package to use.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [ cfg.package ];

      # Creating an empty file on empty configuration is desirable, otherwise swayrd will create the file on startup.
      xdg.configFile."swayr/config.toml" =
        mkIf (cfg.settings != { }) { source = finalConfig; };
    }

    (mkIf cfg.systemd.enable {
      systemd.user.services.swayrd = {
        Unit = {
          Description = "A window-switcher & more for sway";
          Documentation = "https://sr.ht/~tsdh/swayr";
          After = [ cfg.systemd.target ];
          PartOf = [ cfg.systemd.target ];
          X-Restart-Triggers = mkIf (cfg.settings != { })
            [ "${config.xdg.configFile."swayr/config.toml".source}" ];
        };
        Service = {
          Environment = [ "RUST_BACKTRACE=1" ];
          ExecStart = "${cfg.package}/bin/swayrd";
          Restart = "on-failure";
        };
        Install.WantedBy = [ cfg.systemd.target ];
      };
    })
  ]);
}
