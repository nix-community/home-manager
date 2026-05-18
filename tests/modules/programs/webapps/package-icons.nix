{ config, pkgs, ... }:

{
  xdg.enable = true;

  test.stubs = {
    chromium = {
      name = "chromium";
      buildScript = ''
        mkdir -p $out/bin
        touch $out/bin/chromium
        chmod +x $out/bin/chromium
      '';
    };

    mockicontheme = {
      outPath = null;
      buildScript = ''
        mkdir -p $out/share/icons
        echo "mock test icon" > $out/share/icons/test.svg
      '';
    };
  };

  programs.webApps = {
    enable = true;
    browser = pkgs.chromium;

    apps = {
      # Test with a package path using stubbed package
      package-icon-test = {
        url = "https://example.com";
        name = "Package Icon Test";
        # Use mock icon theme package created by test.stubs
        icon = "${pkgs.mockicontheme}/share/icons/test.svg";
        categories = [ "Network" ];
      };

      # Test with string icon name for comparison
      string-icon-test = {
        url = "https://example2.com";
        name = "String Icon Test";
        icon = "folder";
        categories = [ "Network" ];
      };
    };
  };

  # Test that the desktop entries are created correctly
  nmt.script = ''
    # Check that desktop entries exist in the correct location
    assertFileExists "$TESTED/home-path/share/applications/webapp-package-icon-test.desktop"
    assertFileExists "$TESTED/home-path/share/applications/webapp-string-icon-test.desktop"

    # Check that package-icon-test has the package-based icon path
    # Note: test.stubs creates packages named "dummy" in the Nix store
    assertFileContains "$TESTED/home-path/share/applications/webapp-package-icon-test.desktop" \
      'Icon=/nix/store/'
    assertFileContains "$TESTED/home-path/share/applications/webapp-package-icon-test.desktop" \
      'dummy'
    assertFileContains "$TESTED/home-path/share/applications/webapp-package-icon-test.desktop" \
      'test.svg'

    # Check that string-icon-test has the string icon name
    assertFileContains "$TESTED/home-path/share/applications/webapp-string-icon-test.desktop" \
      'Icon=folder'

    # Verify the URLs are correct
    assertFileContains "$TESTED/home-path/share/applications/webapp-package-icon-test.desktop" \
      'https://example.com'
    assertFileContains "$TESTED/home-path/share/applications/webapp-string-icon-test.desktop" \
      'https://example2.com'

    # Check the app mode launch commands are correct
    assertFileContains "$TESTED/home-path/share/applications/webapp-package-icon-test.desktop" \
      'Exec=@chromium@/bin/chromium --app=https://example.com'
    assertFileContains "$TESTED/home-path/share/applications/webapp-string-icon-test.desktop" \
      'Exec=@chromium@/bin/chromium --app=https://example2.com'

    # Check the proper generic names are set
    assertFileContains "$TESTED/home-path/share/applications/webapp-package-icon-test.desktop" \
      'GenericName=Package Icon Test Web App'
    assertFileContains "$TESTED/home-path/share/applications/webapp-string-icon-test.desktop" \
      'GenericName=String Icon Test Web App'
  '';
}
