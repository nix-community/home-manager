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

  cfg = config.programs.ahoviewer;
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];
  options.programs.ahoviewer = {
    enable = mkEnableOption "ahoviewer";
    package = mkPackageOption pkgs "ahoviewer" { nullable = true; };
    config = mkOption {
      type = with types; either str path;
      default = "";
      example = ''
        ZoomMode = "M";
        Geometry :
        {
            x = 964;
            y = 574;
            w = 948;
            h = 498;
        };
        BooruWidth = 382;
        TagViewPosition = 318;
        SmartNavigation = true;
        StoreRecentFiles = false;
        RememberLastFile = false;
        SaveThumbnails = false;
        AutoOpenArchive = false;
        BooruBrowserVisible = true;
      '';
      description = ''
        Configuration settings for ahoviewer. All the available options
        can be found editing the preferences in the GUI and looking at
        $XDG_CONFIG_HOME/ahoviewer/ahoviewer.cfg
      '';
    };
    plugins = mkOption {
      type = with types; listOf package;
      default = [ ];
      description = ''
        List of plugins for ahoviewer.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.ahoviewer" pkgs lib.platforms.linux)
    ];

    xdg.configFile."ahoviewer/ahoviewer.cfg" = mkIf (cfg.config != "") {
      source = if lib.isPath cfg.config then cfg.config else pkgs.writeText "ahoviewer.cfg" cfg.config;
    };
    xdg.dataFile = mkIf (cfg.plugins != [ ]) (
      lib.listToAttrs (
        map (p: lib.nameValuePair "ahoviewer/plugins/${p.pname}" { source = p; }) cfg.plugins
      )
    );
  };
}
