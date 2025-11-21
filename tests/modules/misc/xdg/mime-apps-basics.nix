{ pkgs, ... }:

{
  xdg.mimeApps = {
    enable = true;
    associations = {
      added = {
        "image/png" = [
          "foo1.desktop"
          "foo2.desktop"
          "foo3.desktop"
        ];
        "image/jpeg" = "foo4.desktop";
      };
      removed = {
        "image/png" = "foo5.desktop";
      };
    };
    defaultApplications = {
      "image/png" = [
        "default1.desktop"
        "default2.desktop"
      ];
    };
    defaultApplicationPackages = [
      (pkgs.makeDesktopItem {
        type = "Application";
        name = "test";
        desktopName = "Test";
        mimeTypes = [
          "image/png"
          "image/svg+xml"
        ];
      })
    ];
  };

  nmt.script = ''
    assertFileExists home-files/.config/mimeapps.list
    assertFileContent \
      home-files/.config/mimeapps.list \
      ${./mime-apps-basics-expected.ini}
  '';
}
