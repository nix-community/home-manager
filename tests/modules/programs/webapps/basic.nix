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
        github = {
          url = "https://github.com";
        };
      };
    };

    nmt.script = ''
      # Check that the desktop entry was created
      assertFileExists home-path/share/applications/webapp-github.desktop

      # Check basic desktop entry content
      assertFileRegex home-path/share/applications/webapp-github.desktop \
        'Name=github'
      assertFileRegex home-path/share/applications/webapp-github.desktop \
        'GenericName=github Web App'
      assertFileRegex home-path/share/applications/webapp-github.desktop \
        'Type=Application'
      assertFileRegex home-path/share/applications/webapp-github.desktop \
        'Terminal=false'

      # Check the exec command contains chromium with --app
      assertFileRegex home-path/share/applications/webapp-github.desktop \
        'Exec=.*chromium.*--app=https://github.com'

      # Check categories
      assertFileRegex home-path/share/applications/webapp-github.desktop \
        'Categories=Network;WebBrowser'

      # Check StartupWMClass
      assertFileRegex home-path/share/applications/webapp-github.desktop \
        'StartupWMClass=chromium-webapp-github'
    '';
  };
}
