{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.eww;
  ewwCmd = "${cfg.package}/bin/eww";
in {
  meta.maintainers = [ hm.maintainers.mainrs maintainers.eveeifyeve ];

  options.programs.eww = {
    enable = mkEnableOption "eww";

    package = mkOption {
      type = types.package;
      default = pkgs.eww;
      defaultText = literalExpression "pkgs.eww";
      example = literalExpression "pkgs.eww";
      description = ''
        The eww package to install.
      '';
    };

    yuckConfig = mkOption {
      type = types.nullOr types.lines;
      default = null;
      example = ''
        (defwindow example
          :monitor 0
          :geometry (geometry :x "0%"
                               :y "20px"
                               :width "90%"
                               :height "30px"
                               :anchor "top center")
          :stacking "fg"
          :reserve (struts :distance "40px" :side "top")
          :windowtype "dock"
          :wm-ignore false
        "example content")
      '';
      description = ''
        The content that gets symlinked to
        {file} `$XDG_CONFIG_HOME/eww/eww.yuck`.
      '';
    };

    scssConfig = mkOption {
      type = types.nullOr types.lines;
      default = null;
      example = ''
        window {
          background: pink;
        }
      '';
      description = ''
        The directory that gets symlinked to
        {file} `$XDG_CONFIG_HOME/eww/eww.scss`.
      '';
    };

    configDir = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = literalExpression "./eww-config-dir";
      description = ''
        The directory that gets symlinked to
        {file}`$XDG_CONFIG_HOME/eww`.
      '';
    };

    systemd.enable = mkEnableOption "Launches Eww Daemon";

    systemd.target = mkOption {
      type = types.str;
      default = "graphical-session.target";
      example = "sway-session.target";
      description = ''
        The systemd target that will automatically start the Eww service.

        When setting this value to `"sway-session.target"`,
        make sure to also enable {option}`wayland.windowManager.sway.systemd.enable`,
        otherwise the service may never be started.
      '';
    };

    enableBashIntegration = mkEnableOption "Bash integration" // {
      default = true;
    };

    enableZshIntegration = mkEnableOption "Zsh integration" // {
      default = true;
    };

    enableFishIntegration = mkEnableOption "Fish integration" // {
      default = true;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
          {
            assertion = cfg.configDir != null && (cfg.scssConfig != null || cfg.yuckConfig != null);
            message = "You cannot specify `programs.eww.yuckConfig` and `programs.eww.scssConfig` if you have specified `programs.eww.configDir`";
          }
        ];

      home.packages = [ cfg.package ];

      programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
        if [[ $TERM != "dumb" ]]; then
          eval "$(${ewwCmd} shell-completions --shell bash)"
        fi
      '';

      programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
        if [[ $TERM != "dumb" ]]; then
          eval "$(${ewwCmd} shell-completions --shell zsh)"
        fi
      '';

      programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration ''
        if test "$TERM" != "dumb"
          eval "$(${ewwCmd} shell-completions --shell fish)"
        end
      '';
    }

    (mkIf (cfg.configDir != null) { xdg.configFile."eww".source = cfg.configDir; })

    (mkIf (cfg.yuckConfig != null) { xdg.configFile."eww/eww.yuck".text = cfg.yuckConfig; })

    (mkIf (cfg.scssConfig != null) { xdg.configFile."eww/eww.scss".text = cfg.scssConfig; })

    (mkIf cfg.systemd.enable {
      systemd.user.services.eww = {
        Unit = {
          Description = "ElKowars wacky widgets daemon";
          Documentation = "https://elkowar.github.io/eww/";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = "${ewwCmd} daemon --no-daemonize";
          ExecStop = "${ewwCmd} kill";
          ExecReload = "${ewwCmd} reload";
        };

        Install = { WantedBy = [ cfg.systemd.target ]; };
      };
    })
  ]);
}
