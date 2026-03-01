{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkMerge;

  cfg = config.programs.eww;
in
{
  meta.maintainers = [
    lib.hm.maintainers.mainrs
    lib.maintainers.eveeifyeve
  ];

  options.programs.eww = {
    enable = lib.mkEnableOption "eww";
    package = lib.mkPackageOption pkgs "eww" { };

    yuckConfig = lib.mkOption {
      type = lib.types.nullOr lib.types.lines;
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

    scssConfig = lib.mkOption {
      type = lib.types.nullOr lib.types.lines;
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

    systemd = {
      enable = lib.mkEnableOption "Launches Eww Daemon";
      target = lib.mkOption {
        type = lib.types.str;
        default = "graphical-session.target";
        example = "sway-session.target";
        description = ''
          The systemd target that will automatically start the Eww service.

          When setting this value to `"sway-session.target"`,
          make sure to also enable {option}`wayland.windowManager.sway.systemd.enable`,
          otherwise the service may never be started.
        '';
      };
    };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };
    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };
    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };
  };
  config =
    let
      ewwCmd = lib.getExe cfg.package;
    in
    mkIf cfg.enable (mkMerge [
      {
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
            ExecStart = "${cfg.package} daemon --no-daemonize";
            ExecStop = "${cfg.package} kill";
            ExecReload = "${cfg.package} reload";
          };

          Install = {
            WantedBy = [ cfg.systemd.target ];
          };
        };
      })
    ]);
}
