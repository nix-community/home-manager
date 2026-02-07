{
  config,
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

    programs.webApps = {
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

      # Check extra browser options are included
      assertFileRegex home-path/share/applications/webapp-gmail.desktop \
        'Exec=.*--profile-directory=Profile\\ 2.*'
      assertFileRegex home-path/share/applications/webapp-gmail.desktop \
        'Exec=.*--user-data-dir=/tmp/gmail-profile.*'

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
