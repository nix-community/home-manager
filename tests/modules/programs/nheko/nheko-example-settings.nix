{ pkgs, ... }:

let
  configDir = if pkgs.stdenv.isDarwin then
    "home-files/Library/Application Support"
  else
    "home-files/.config";
in {
  programs.nheko = {
    enable = true;

    settings = {
      general = { disableCertificateValidation = false; };

      auth = {
        accessToken = "MY_ACCESS_TOKEN";
        deviceId = "MY_DEVICE";
        homeServer = "https://matrix-client.matrix.org:443";
        userId = "@@user:matrix.org";
      };

      sidebar = { width = 416; };

      settings = { scaleFactor = 0.7; };

      user = {
        alertOnNotification = true;
        animateImagesOnHover = false;
        automaticallyShareKeysWithTrustedUsers = false;
        avatarCircles = true;
        bubblesEnabled = false;
        decryptSidebar = true;
        desktopNotifications = true;
        emojiFontFamily = "Noto Emoji";
        exposeDbusApi = false;
        fontFamily = "JetBrainsMonoMedium Nerd Font Mono";
        fontSize = 9;
        groupView = true;
        markdownEnabled = true;
        minorEvents = false;
        mobileMode = false;
        mutedTags = "global";
        onlineKeyBackup = false;
        onlyShareKeysWithVerifiedUsers = false;
        openImageExternal = false;
        openVideoExternal = false;
        presence = "AutomaticPresence";
        privacyScreen = false;
        privacyScreenTimeout = 0;
        readReceipts = true;
        ringtone = "Mute";
        shareKeysWithTrustedUsers = true;
        smallAvatarsEnabled = false;
        "sidebar\\communityListWidth" = 40;
        "sidebar\\roomListWidth" = 308;
        sortByUnread = true;
        spaceNotifications = true;
        theme = "dark";
        "timeline\\buttons" = true;
        "timeline\\enlargeEmojiOnlyMsg" = true;
        "timeline\\maxWidth" = 0;
        "timeline\\messageHoverHighlight" = false;
        typingNotifications = true;
        useIdenticon = true;
        useStunServer = false;
        "window\\startInTray" = false;
        "window\\tray" = true;
      };

      window = {
        height = 482;
        width = 950;
      };
    };
  };

  nmt.script = ''
    assertFileContent \
      "${configDir}/nheko/nheko.conf" \
      ${./nheko-example-settings-expected-config.ini}
  '';
}
