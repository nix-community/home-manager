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
    test.stubs.firefox = {
      name = "firefox";
      buildScript = ''
        mkdir -p $out/bin
        touch $out/bin/firefox
        chmod +x $out/bin/firefox
      '';
    };

    programs.webapps = {
      enable = true;
      browser = pkgs.chromium;

      apps = {
        # Uses the top-level browser (chromium).
        github = {
          url = "https://github.com";
        };

        # Overrides the browser for just this app.
        youtube = {
          url = "https://youtube.com";
          browser = pkgs.firefox;
        };
      };
    };

    nmt.script = ''
      assertFileExists home-path/share/applications/webapp-github.desktop
      assertFileExists home-path/share/applications/webapp-youtube.desktop

      # github uses the top-level chromium (--app mode)
      assertFileRegex home-path/share/applications/webapp-github.desktop \
        'Exec=.*chromium.*--app=https://github.com'

      # youtube overrides to firefox (no --app mode)
      assertFileRegex home-path/share/applications/webapp-youtube.desktop \
        'Exec=.*firefox.*https://youtube.com'
      assertFileNotRegex home-path/share/applications/webapp-youtube.desktop \
        'Exec=.*--app.*'
    '';
  };
}
