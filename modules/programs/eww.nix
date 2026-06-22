{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.programs.eww;
in
{
  meta.maintainers = [
    lib.hm.maintainers.mainrs
    lib.maintainers.eveeifyeve
  ];

  imports =
    (map
      (
        shell:
        lib.mkRemovedOptionModule [
          "programs"
          "eww"
          "enable${shell}Integration"
        ] "This option is no longer necessary. Shell completions are now installed with eww by nixpkgs."
      )
      [
        "Bash"
        "Zsh"
        "Fish"
      ]
    )
    ++ [
      (lib.mkRemovedOptionModule
        [
          "programs"
          "eww"
          "configDir"
        ]
        "programs.eww.configDir is now deprecated, please use programs.eww.yuckConfig and programs.eww.scssConfig instead."
      )
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
        {file}`$XDG_CONFIG_HOME/eww/eww.yuck`.
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
        {file}`$XDG_CONFIG_HOME/eww/eww.scss`.
      '';
    };

    systemd = {
      enable = lib.mkEnableOption "Launches Eww Daemon";

      target = lib.mkOption {
        type = lib.types.str;
        default = config.wayland.systemd.target;
        defaultText = lib.literalExpression "config.wayland.systemd.target";
        description = ''
          Systemd target to bind to.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile = {
      "eww/eww.yuck" = mkIf (cfg.yuckConfig != null) { text = cfg.yuckConfig; };
      "eww/eww.scss" = mkIf (cfg.scssConfig != null) { text = cfg.scssConfig; };
    };

    systemd = mkIf cfg.systemd.enable {
      user.services.eww = {
        Unit = {
          Description = "ElKowars wacky widgets daemon";
          Documentation = "https://elkowar.github.io/eww/";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };

        Service =
          let
            exe = lib.getExe cfg.package;
          in
          {
            ExecStart = "${exe} daemon --no-daemonize";
            ExecStop = "${exe} kill";
            ExecReload = "${exe} reload";
          };

        Install = {
          WantedBy = [ cfg.systemd.target ];
        };
      };
    };
  };
}
