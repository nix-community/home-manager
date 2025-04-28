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

  cfg = config.programs.mpvpaper;
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

  options.programs.mpvpaper = {
    enable = mkEnableOption "mpvpaper";
    package = mkPackageOption pkgs "mpvpaper" { nullable = true; };
    pauseList = mkOption {
      type = types.lines;
      default = "";
      example = ''
        firefox
        steam
        obs
      '';
      description = ''
        List of program names that will cause mpvpaper to pause.
        Programs must be separed by spaces or newlines.
      '';
    };
    stopList = mkOption {
      type = types.lines;
      default = "";
      example = ''
        firefox
        steam
        obs
      '';
      description = ''
        List of program names that will cause mpvpaper to stop.
        Programs must be separed by spaces or newlines.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.mpvpaper" pkgs lib.platforms.linux)
    ];

    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."mpvpaper/pauselist".text = mkIf (cfg.pauseList != "") cfg.pauseList;
    xdg.configFile."mpvpaper/stoplist".text = mkIf (cfg.stopList != "") cfg.stopList;
  };
}
