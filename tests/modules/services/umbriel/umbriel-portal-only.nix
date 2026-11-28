{
  wayland.windowManager.umbriel = {
    enable = true;
    package = null;
    systemd.enable = false;
  };

  test.stubs = {
    umbriel = {
      outPath = null;
      buildScript = ''
        mkdir -p $out/bin
        touch $out/bin/umbriel
      '';
    };
    xdg-desktop-portal-umbriel = {
      outPath = null;
      buildScript = ''
        mkdir -p $out/share/xdg-desktop-portal/portals

        touch $out/share/xdg-desktop-portal/portals/umbriel.portal
        touch $out/share/xdg-desktop-portal/umbriel-portals.conf
      '';
    };
  };

  nmt.script = ''
    assertPathNotExists home-path/bin/umbriel
    assertFileExists home-path/share/xdg-desktop-portal/portals/umbriel.portal
    assertFileExists home-path/share/xdg-desktop-portal/umbriel-portals.conf
  '';
}
