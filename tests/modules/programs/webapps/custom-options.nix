{
  pkgs,
  ...
}:

{
  config = {
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
        gmail = {
          url = "https://mail.google.com";
          name = "Gmail";
          categories = [
            "Office"
            "Network"
            "Email"
          ];
          mimeTypes = [ "x-scheme-handler/mailto" ];
          startupWmClass = "gmail-webapp";
          extraOptions = {
            "profile-directory" = "Profile 2";
            "user-data-dir" = "/tmp/gmail-profile";
            "window-size" = 1280;
            incognito = true;
            "disable-sync" = false;
          };
        };

        simple = {
          url = "https://example.com";
          # Test minimal configuration
        };
      };
    };

    nmt.script = ''
      # Test Gmail with custom options
      assertFileExists home-path/share/applications/webapp-gmail.desktop

      # Check custom name and categories
      assertFileRegex home-path/share/applications/webapp-gmail.desktop \
        'Name=Gmail'
      assertFileRegex home-path/share/applications/webapp-gmail.desktop \
        'Categories=Office;Network;Email'

      # Check MIME type support
      assertFileRegex home-path/share/applications/webapp-gmail.desktop \
        'MimeType=x-scheme-handler/mailto'

      # Check custom StartupWMClass
      assertFileRegex home-path/share/applications/webapp-gmail.desktop \
        'StartupWMClass=gmail-webapp'

      # String options with reserved characters (the space in "Profile 2") are
      # wrapped in double quotes per the Desktop Entry spec; plain values stay
      # unquoted.
      assertFileRegex home-path/share/applications/webapp-gmail.desktop \
        'Exec=.*"--profile-directory=Profile 2".*'
      assertFileRegex home-path/share/applications/webapp-gmail.desktop \
        'Exec=.*--user-data-dir=/tmp/gmail-profile.*'

      # Integer options render as --name=value.
      assertFileRegex home-path/share/applications/webapp-gmail.desktop \
        'Exec=.*--window-size=1280.*'

      # Boolean true renders as a bare switch (never --name=value); false is
      # omitted entirely.
      assertFileRegex home-path/share/applications/webapp-gmail.desktop \
        'Exec=.* --incognito'
      assertFileNotRegex home-path/share/applications/webapp-gmail.desktop \
        'Exec=.* --incognito='
      assertFileNotRegex home-path/share/applications/webapp-gmail.desktop \
        'disable-sync'

      # Test simple app with defaults
      assertFileExists home-path/share/applications/webapp-simple.desktop
      assertFileRegex home-path/share/applications/webapp-simple.desktop \
        'Name=simple'
      assertFileRegex home-path/share/applications/webapp-simple.desktop \
        'Categories=Network;WebBrowser'
      assertFileRegex home-path/share/applications/webapp-simple.desktop \
        'StartupWMClass=chromium-webapp-simple'
    '';
  };
}
