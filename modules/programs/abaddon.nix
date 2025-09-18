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

  cfg = config.programs.abaddon;
  iniFormat = pkgs.formats.ini { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];
  options.programs.abaddon = {
    enable = mkEnableOption "abaddon";
    package = mkPackageOption pkgs "abaddon" { nullable = true; };
    settings = mkOption {
      inherit (iniFormat) type;
      default = { };
      example = {
        windows.hideconsole = true;
        notifications.enabled = false;
        discord = {
          token = "MZ1yGvKTjE0rY0cV8i47CjAa.uRHQPq.Xb1Mk2nEhe-4iUcrGOuegj57zMC";
          autoconnect = true;
        };

        gui = {
          stock_emojis = false;
          animations = false;
          alt_menu = true;
          hide_to_tray = true;
        };
      };
      description = ''
        Configuration settings for abaddon. All the available options can be found here:
        <https://github.com/uowuo/abaddon?tab=readme-ov-file#settings>
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."abaddon/abaddon.ini" = mkIf (cfg.settings != { }) {
      source = iniFormat.generate "abaddon.ini" cfg.settings;
    };
  };
}
