{ pkgs, ... }:

{
  config = {
    # A Chromium-family browser whose package name is `ungoogled-chromium` but
    # whose launch binary is `chromium` (executable name != package name).
    test.stubs.ungoogled-chromium = {
      name = "ungoogled-chromium";
      extraAttrs.meta.mainProgram = "chromium";
      buildScript = ''
        mkdir -p $out/bin
        touch $out/bin/chromium
        chmod +x $out/bin/chromium
      '';
    };

    # A browser that is not in the known-Chromium list, to exercise the fallback.
    test.stubs.qutebrowser = {
      name = "qutebrowser";
      buildScript = ''
        mkdir -p $out/bin
        touch $out/bin/qutebrowser
        chmod +x $out/bin/qutebrowser
      '';
    };

    programs.webapps = {
      enable = true;
      browser = pkgs.ungoogled-chromium;

      apps = {
        # Inherits the top-level browser; binary resolves via meta.mainProgram.
        github.url = "https://github.com";

        # An unlisted browser opens the URL in a normal window (no --app mode).
        docs = {
          url = "https://qutebrowser.org";
          browser = pkgs.qutebrowser;
        };
      };
    };

    nmt.script = ''
      assertFileExists home-path/share/applications/webapp-github.desktop
      assertFileExists home-path/share/applications/webapp-docs.desktop

      # The launch binary resolves via meta.mainProgram (chromium), NOT the
      # package name (ungoogled-chromium); a known Chromium browser gets --app.
      assertFileContains home-path/share/applications/webapp-github.desktop \
        'Exec=@ungoogled-chromium@/bin/chromium --app=https://github.com'
      assertFileNotRegex home-path/share/applications/webapp-github.desktop \
        'bin/ungoogled-chromium'

      # An unlisted browser opens the URL in a normal window, with no --app flag.
      assertFileContains home-path/share/applications/webapp-docs.desktop \
        'Exec=@qutebrowser@/bin/qutebrowser https://qutebrowser.org'
      assertFileNotRegex home-path/share/applications/webapp-docs.desktop \
        'Exec=.*--app.*'
    '';
  };
}
