{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    xdg.desktopEntries = {
      full = { # full definition
        type = "Application";
        exec = "test --option";
        icon = "test";
        comment = "My Application";
        terminal = true;
        name = "Test";
        genericName = "Web Browser";
        mimeType = [ "text/html" "text/xml" ];
        categories = [ "Network" "WebBrowser" ];
        startupNotify = false;
        extraConfig = ''
          [X-ExtraSection]
          Exec=foo -o
        '';
        settings = {
          Keywords = "calc;math";
          DBusActivatable = "false";
        };
        fileValidation = true;
      };
      min = { # minimal definition
        exec = "test --option";
        name = "Test";
      };
    };

    #testing that preexisting entries in the store are overridden
    home.packages = [
      (pkgs.makeDesktopItem {
        name = "full";
        desktopName = "We don't want this";
        exec = "no";
      })
      (pkgs.makeDesktopItem {
        name = "min";
        desktopName = "We don't want this";
        exec = "no";
      })
    ];

    nmt.script = ''
      assertFileExists home-path/share/applications/full.desktop
      assertFileExists home-path/share/applications/min.desktop
      assertFileContent home-path/share/applications/full.desktop \
        ${./desktop-full-expected.desktop}
      assertFileContent home-path/share/applications/min.desktop \
        ${./desktop-min-expected.desktop}
    '';
  };
}
