{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.eww;
  ewwCmd = "${cfg.package}/bin/eww";

in {
  meta.maintainers = [ hm.maintainers.mainrs ];

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

    configYuck = mkOption {
      type = types.lines;
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

    configScss = mkOption {
      type = types.lines;
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
      type = types.path;
      example = literalExpression "./eww-config-dir";
      description = ''
        The directory that gets symlinked to
        {file}`$XDG_CONFIG_HOME/eww`.

        This Option is now deprecated. Please use `programs.eww.configYuck` & `programs.eww.configScss` instead.
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
      warnings = optional (isList cfg.configDir) ''
        `programs.eww.configDir` is now deprecated. Please use `programs.eww.configYuck` & `programs.eww.configScss` instead.
      '';
      home.packages = [ cfg.package ];
      xdg.configFile."eww".source = cfg.configDir;

      programs.bash.initExtra = let ewwCmd = "${cfg.package}/bin/eww";
      in mkIf cfg.enableBashIntegration ''
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

    (mkIf cfg.systemd.enable {
      systemd.user.services.eww = {
        Unit = {
          Description = "ElKowars wacky widgets";
          Documentation = "https://elkowar.github.io/eww/";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = "${cfg.package} daemon --no-damonize";
          ExecStop = "${cfg.package} kill";
          ExecReload = "${cfg.package} reload";
        };

        Install = { WantedBy = [ cfg.systemd.target ]; };
      };
    })
  ]);
}
