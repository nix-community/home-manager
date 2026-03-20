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

  cfg = config.programs.am2rlauncher;
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];
  options.programs.am2rlauncher = {
    enable = mkEnableOption "am2rlauncher";
    package = mkPackageOption pkgs "am2rlauncher" { nullable = true; };
    config = mkOption {
      type = with types; either str path;
      default = "";
      example = ''
        <?xml version="1.0" encoding="utf-8"?>
        <settings xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" AutoUpdateAM2R="false" AutoUpdateLauncher="true" Language="English" MusicHQPC="false" MusicHQAndroid="false" MirrorIndex="0" ProfileIndex="null" CustomMirrorEnabled="false" CustomMirrorText="" ProfileDebugLog="true" Width="600" Height="600" IsMaximized="false" />
      '';
      description = ''
        Config file for am2rlauncher in XML format. You can see the available options
        by modifying the settings in the GUI and looking at $XDG_CONFIG_HOME/AM2RLauncher/config.xml.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.am2rlauncher" pkgs lib.platforms.linux)
    ];

    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."AM2RLauncher/config.xml" = mkIf (cfg.config != "") {
      source =
        if lib.isPath cfg.config then cfg.config else pkgs.writeText "am2rlauncher-config.xml" cfg.config;
    };
  };
}
