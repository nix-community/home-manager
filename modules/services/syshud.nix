{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkPackageOption
    mkOption
    mkIf
    ;
  cfg = config.services.syshud;

  iniFormat = pkgs.formats.ini { };
in
{
  meta.maintainers = [ lib.maintainers.yarn ];

  options.services.syshud = {
    enable = mkEnableOption "syshud";
    package = mkPackageOption pkgs "syshud" { };
    settings = mkOption {
      type = iniFormat.type.nestedTypes.elemType;
      default = { };
      example = lib.literalExpression ''
        {
          position = "bottom";
          orientation = "h";
          width = 300;
          height = 50;
          icon-size = 26;
          show-percentage = true;
          margins = "0 0 0 0";
          timeout = 3;
          transition-time = 250;
          listeners = "audio_in,audio_out,backlight";
          backlight-path = "/sys/class/backlight/gmux_backlight";
          keyboard-path = "/dev/input/eventXX";
        }
      '';
      description = ''
        Configuration for syshud.
        All available options can be found here:
        <https://github.com/System64fumo/syshud?tab=readme-ov-file#configuration>
      '';
    };
    style = mkOption {
      type = lib.types.nullOr (lib.types.either lib.types.path lib.types.lines);
      default = null;
      description = ''
        Custom CSS style for syshud.
        If the value is set to a path literal, then the path will be used as the css file.
        Default style is available here:
        <https://github.com/System64fumo/syshud/blob/main/style.css>
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.syshud" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services.syshud = {
      Install = {
        WantedBy = [ config.wayland.systemd.target ];
      };

      Unit = {
        ConditionEnvironment = "WAYLAND_DISPLAY";
        Description = "syshud";
        After = [ config.wayland.systemd.target ];
        PartOf = [ config.wayland.systemd.target ];
      };

      Service = {
        ExecStart = lib.getExe cfg.package;
        Environment = [
          "PATH=$PATH:${lib.makeBinPath [ cfg.package ]}"
        ];
        Restart = "always";
        RestartSec = 10;
      };
    };

    xdg.configFile."sys64/hud/config.conf" = mkIf (cfg.settings != { }) {
      source = iniFormat.generate "config.conf" { main = cfg.settings; };
    };

    xdg.configFile."sys64/hud/style.css" = mkIf (cfg.style != null) {
      source =
        if builtins.isPath cfg.style || lib.isStorePath cfg.style then
          cfg.style
        else
          pkgs.writeText "sys64/hud/style.css" cfg.style;
    };
  };
}
