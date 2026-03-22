{
  config,
  pkgs,
  ...
}:

{
  config = {
    test.stubs.firefox = {
      name = "firefox";
      buildScript = ''
        mkdir -p $out/bin
        touch $out/bin/firefox
        chmod +x $out/bin/firefox
      '';
    };

    programs.webApps = {
      enable = true;
      browser = pkgs.firefox;

      apps = {
        youtube = {
          url = "https://youtube.com";
          name = "YouTube";
          icon = "applications-multimedia";
          categories = [
            "AudioVideo"
            "Network"
          ];
        };
      };
    };

    nmt.script = ''
      # Check that the desktop entry was created
      assertFileExists home-path/share/applications/webapp-youtube.desktop

      # Check custom name
      assertFileRegex home-path/share/applications/webapp-youtube.desktop \
        'Name=YouTube'

      # Check Firefox exec (no --app mode for Firefox)
      assertFileRegex home-path/share/applications/webapp-youtube.desktop \
        'Exec=.*firefox.*https://youtube.com'

      # Make sure it doesn't contain --app (Firefox doesn't support it)
      assertFileNotRegex home-path/share/applications/webapp-youtube.desktop \
        'Exec=.*--app.*'

      # Check custom categories
      assertFileRegex home-path/share/applications/webapp-youtube.desktop \
        'Categories=AudioVideo;Network'

      # Check icon
      assertFileRegex home-path/share/applications/webapp-youtube.desktop \
        'Icon=applications-multimedia'
    '';
  };
}
