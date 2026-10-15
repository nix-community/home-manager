{
  pkgs,
  ...
}:

{
  test.stubs.chromium = {
    name = "chromium";
    buildScript = ''
      mkdir -p $out/bin
      touch $out/bin/chromium
      chmod +x $out/bin/chromium
    '';
  };

  programs.webapps = {
    enable = true;
    browser = pkgs.chromium;

    apps = {
      # Method 1: Using theme icon names (most compatible)
      gmail = {
        url = "https://mail.google.com";
        name = "Gmail";
        icon = "mail-client";
        categories = [
          "Network"
          "Email"
          "Office"
        ];
        mimeTypes = [ "x-scheme-handler/mailto" ];
        startupWmClass = "gmail-webapp";
      };

      # Method 2: Using general theme icon names
      calendar = {
        url = "https://calendar.google.com";
        name = "Google Calendar";
        icon = "calendar";
        categories = [
          "Office"
          "Calendar"
        ];
      };

      # Method 3: Using web browser icon as fallback
      slack = {
        url = "https://slack.com";
        name = "Slack";
        icon = "web-browser";
        categories = [
          "Network"
          "Chat"
        ];
      };

      # Method 4: Using application icon
      discord = {
        url = "https://discord.com/app";
        name = "Discord";
        icon = "application-x-executable";
        categories = [
          "Network"
          "Chat"
        ];
      };

      # Method 5: Using folder icon (always available)
      github = {
        url = "https://github.com";
        name = "GitHub";
        icon = "folder";
        categories = [
          "Development"
          "Network"
        ];
      };
    };
  };

  nmt.script = ''
    assertFileExists home-path/share/applications/webapp-gmail.desktop
    assertFileExists home-path/share/applications/webapp-calendar.desktop
    assertFileExists home-path/share/applications/webapp-slack.desktop
    assertFileExists home-path/share/applications/webapp-discord.desktop
    assertFileExists home-path/share/applications/webapp-github.desktop

    # Gmail: theme-name icon, custom categories, MIME handler and WM class.
    assertFileRegex home-path/share/applications/webapp-gmail.desktop \
      'Name=Gmail'
    assertFileRegex home-path/share/applications/webapp-gmail.desktop \
      'Icon=mail-client'
    assertFileRegex home-path/share/applications/webapp-gmail.desktop \
      'Categories=Network;Email;Office'
    assertFileRegex home-path/share/applications/webapp-gmail.desktop \
      'MimeType=x-scheme-handler/mailto'
    assertFileRegex home-path/share/applications/webapp-gmail.desktop \
      'StartupWMClass=gmail-webapp'
    assertFileRegex home-path/share/applications/webapp-gmail.desktop \
      'Exec=.*--app=https://mail.google.com'

    # A couple of the other apps: custom display names are honoured.
    assertFileRegex home-path/share/applications/webapp-calendar.desktop \
      'Name=Google Calendar'
    assertFileRegex home-path/share/applications/webapp-discord.desktop \
      'GenericName=Discord Web App'
  '';
}
