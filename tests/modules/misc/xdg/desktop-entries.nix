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
        noDisplay = false;
        prefersNonDefaultGPU = false;
        settings = {
          Keywords = "calc;math";
          DBusActivatable = "false";
        };
        actions = {
          "New-Window" = {
            name = "New Window";
            exec = "test --new-window";
            icon = "test";
          };
          "Default" = { exec = "test --default"; };
        };
      };
      min = { # minimal definition
        name = "Test";
      };
      deprecated = {
        exec = "test --option";
        name = "Test";
        # Deprecated options
        fileValidation = true;
        extraConfig = ''
          [X-ExtraSection]
          Exec=foo -o
        '';
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

    test.asserts.assertions.expected =
      let currentFile = toString ./desktop-entries.nix;
      in [
        ''
          The option definition `fileValidation' in `${currentFile}' no longer has any effect; please remove it.
          Validation of the desktop file is always enabled.
        ''
        ''
          The option definition `extraConfig' in `${currentFile}' no longer has any effect; please remove it.
          The `extraConfig` option of `xdg.desktopEntries` has been removed following a change in Nixpkgs.
        ''
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
