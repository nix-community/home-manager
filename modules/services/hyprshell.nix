{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    types
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  cfg = config.services.hyprshell;

  jsonFormat = pkgs.formats.json { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

  options.services.hyprshell = {
    enable = mkEnableOption "hyprshell";
    package = mkPackageOption pkgs "hyprshell" { nullable = true; };

    settings = mkOption {
      type = jsonFormat.type;
      default = { };
      description = ''
        Configuration settings for hyprshell. All the avaiblable
        options can be found here: <https://github.com/H3rmt/hyprshell/blob/hyprshell-release/CONFIGURE.md#config-options>
      '';
    };

    style = mkOption {
      type = with types; either path lines;
      default = "";
      description = ''
        CSS file for customizing hyprshell. All the available
        options can be found here: <https://github.com/H3rmt/hyprshell/blob/hyprshell-release/CONFIGURE.md#css>
      '';
    };

    systemd = {
      enable = mkEnableOption "the hyprshell Systemd service" // {
        default = true;
      };

      target = mkOption {
        type = types.str;
        default = config.wayland.systemd.target;
        defaultText = lib.literalExpression "config.wayland.systemd.target";
        description = "The Systemd target that will start the hyprshell service";
      };

      args = mkOption {
        type = types.str;
        default = "";
        example = "-vv";
        description = "Arguments to pass to the hyprshell service";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.hyprshell" pkgs lib.platforms.linux)
      {
        assertion = if (cfg.package == null) then (if cfg.systemd.enable then false else true) else true;
        message = "Can't set programs.hyprshell.systemd.enable with the package set to null.";
      }
    ];

    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."hyprshell/config.json" = mkIf (cfg.settings != { }) {
      source = jsonFormat.generate "hyprshell-config" cfg.settings;
    };

    xdg.configFile."hyprshell/style.css" = mkIf (cfg.style != "") {
      source = if lib.isString cfg.style then pkgs.writeText "hyprshell-style" cfg.style else cfg.style;
    };

    systemd.user.services.hyprshell = mkIf (cfg.systemd.enable && (cfg.package != null)) {
      Unit = {
        Description = "Starts Hyprshell daemon";
        After = [ cfg.systemd.target ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${lib.getExe cfg.package} run ${cfg.systemd.args}";
        Restart = "on-failure";
      };
      Install.WantedBy = [ cfg.systemd.target ];
    };
  };
}
