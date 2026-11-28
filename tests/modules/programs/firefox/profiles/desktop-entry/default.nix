modulePath:
{
  config,
  lib,
  ...
}:
let
  cfg = lib.getAttrFromPath modulePath config;
  firefoxMockOverlay = import ../../setup-firefox-mock-overlay.nix modulePath;
  binaryName = lib.removeSuffix "-bin" cfg.wrappedPackageName;
  entryName = "${lib.toLower cfg.name}-default";
in
{
  imports = [ firefoxMockOverlay ];

  config = lib.mkIf config.test.enableBig (
    lib.setAttrByPath modulePath {
      enable = true;
      profiles.default = {
        id = 0;
        desktopEntry = {
          enable = true;
          genericName = "Web Browser";
          icon = "test-icon";
          settings.Keywords = "internet;www;browser;web;explorer";
        };
      };
      profiles.work = {
        id = 1;
        desktopEntry.enable = false;
      };
    }
    // {
      nmt.script = ''
        assertFileExists "home-path/share/applications/${entryName}.desktop"
        assertFileRegex \
          "home-path/share/applications/${entryName}.desktop" \
          '^Exec=.*/bin/${binaryName} --no-remote -P default %U$'
        assertFileContains \
          "home-path/share/applications/${entryName}.desktop" \
          "Name=${cfg.name} (default)"
        assertFileContains \
          "home-path/share/applications/${entryName}.desktop" \
          "GenericName=Web Browser"
        assertFileContains \
          "home-path/share/applications/${entryName}.desktop" \
          "Icon=test-icon"
        assertFileContains \
          "home-path/share/applications/${entryName}.desktop" \
          "Keywords=internet;www;browser;web;explorer"
        assertPathNotExists "home-path/share/applications/${lib.toLower cfg.name}-work.desktop"
      '';
    }
  );
}
