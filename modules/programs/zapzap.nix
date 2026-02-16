{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  iniFormat = pkgs.formats.ini { };
  cfg = config.programs.zapzap;
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];
  options.programs.zapzap = {
    enable = mkEnableOption "zapzap";
    package = mkPackageOption pkgs "zapzap" { nullable = true; };
    settings = mkOption {
      inherit (iniFormat) type;
      default = { };
      example = {
        notification.donation_message = true;
        website.open_page = false;
        system = {
          scale = 150;
          theme = "dark";
          wayland = true;
        };
      };
      description = ''
        Configuration settings for zapzap. All the available options can be found by
        changing the settings from the GUI and looking at $XDG_CONFIG_HOME/ZapZap/ZapZap.conf.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.zapzap" pkgs lib.platforms.linux)
    ];

    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."ZapZap/ZapZap.conf" = mkIf (cfg.settings != { }) {
      source = iniFormat.generate "ZapZap.conf" cfg.settings;
    };
  };
}
