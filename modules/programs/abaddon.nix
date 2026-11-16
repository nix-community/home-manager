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

        These settings are written to the world-readable Nix store, so avoid
        putting a Discord login token in `discord.token`. Abaddon rewrites
        {file}`abaddon.ini` when it exits, which replaces the file Home
        Manager manages, so if you log in from Abaddon's Discord menu,
        consider leaving this option empty and letting Abaddon manage
        {file}`abaddon.ini`.
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
