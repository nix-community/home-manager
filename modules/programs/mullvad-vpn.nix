{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.programs.mullvad-vpn;
  jsonFormat = pkgs.formats.json { };
in
{
  meta.maintainers = [ lib.maintainers.awwpotato ];

  options.programs.mullvad-vpn = {
    enable = lib.mkEnableOption "Mullvad VPN";
    package = lib.mkPackageOption pkgs "mullvad-vpn" { nullable = true; };

    settings = lib.mkOption {
      inherit (jsonFormat) type;
      default = { };
      description = ''
        Written to {file}`XDG_CONFIG_HOME/Mullvad VPN/gui_settings.json` or
        {file}`~/Library/Application Support/Mullvad VPN/gui_settings.json`.
        See <https://github.com/mullvad/mullvadvpn-app/blob/main/desktop/packages/mullvad-vpn/src/main/gui-settings.ts>
        for options.
      '';
      example = {
        preferredLocale = "system";
        autoConnect = false;
        enableSystemNotifications = true;
        monochromaticIcon = false;
        startMinimized = false;
        unpinnedWindow = true;
        browsedForSplitTunnelingApplications = [ ];
        changelogDisplayedForVersion = "";
        updateDismissedForVersion = "";
        animateMap = true;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    home.file."${
      if pkgs.stdenv.hostPlatform.isDarwin then "Library/Application Support" else config.xdg.configHome
    }/Mullvad VPN/gui_settings.json" =
      lib.mkIf (cfg.settings != { }) {
        source = jsonFormat.generate "mullvad-gui-settings" cfg.settings;
      };
  };
}
