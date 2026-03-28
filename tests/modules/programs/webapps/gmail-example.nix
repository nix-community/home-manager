{
  config,
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

  programs.webApps = {
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
}
