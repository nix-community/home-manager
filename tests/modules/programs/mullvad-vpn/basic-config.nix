{ pkgs, ... }:
{
  programs.mullvad-vpn = {
    enable = true;
    settings = {
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

  nmt.script =
    let
      configFile =
        if pkgs.stdenv.isDarwin then
          "home-files/Library/Application\\ Support/Mullvad\\ VPN/gui_settings.json"
        else
          "home-files/.config/Mullvad\\ VPN/gui_settings.json";
    in
    ''
      assertFileExists ${configFile}
      assertFileContent ${configFile} \
        ${pkgs.writeText "settings-expected" ''
          {
            "animateMap": true,
            "autoConnect": false,
            "browsedForSplitTunnelingApplications": [],
            "changelogDisplayedForVersion": "",
            "enableSystemNotifications": true,
            "monochromaticIcon": false,
            "preferredLocale": "system",
            "startMinimized": false,
            "unpinnedWindow": true,
            "updateDismissedForVersion": ""
          }
        ''}
    '';
}
