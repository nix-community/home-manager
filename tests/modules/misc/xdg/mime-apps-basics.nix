{ pkgs, realPkgs, ... }:

{
  nixpkgs.overlays = [ (_: _: { inherit (realPkgs) python3; }) ];

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
      (pkgs.runCommand "nested-desktop-entry" { } ''
        mkdir -p "$out/share/applications/vendor"
        cat > "$out/share/applications/vendor/viewer.desktop" <<'EOF'
        [Desktop Entry]
        Type=Application
        Name=Viewer
        Exec=true
        MimeType=application/pdf;
        EOF
      '')
    ];
  };

  nmt.script = ''
    assertFileExists home-files/.config/mimeapps.list
    assertFileContent \
      home-files/.config/mimeapps.list \
      ${./mime-apps-basics-expected.ini}
  '';
}
