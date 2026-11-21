{
  wayland.windowManager.umbriel = {
    enable = true;

    # Disabling package should not add umbriel to the `$PATH`
    package = null;

    # Disabling systemd and portal should not link the files
    portalPackage = null;
    systemd.enable = false;

    # Empty settings should not generate `$XDG_CONFIG_HOME/umbriel/config.toml`
    settings = { };
  };

  # Stubs with `outPath = null` produce real derivations so that the negative
  # assertions below are meaningful. Without them, scrubbed packages can never
  # be linked by `buildEnv` and the assertions would trivially pass even if the
  # module incorrectly added them.
  test.stubs = {
    umbriel = {
      outPath = null;
      buildScript = ''
        mkdir -p $out/bin $out/share/systemd/user

        touch $out/bin/umbriel
        touch $out/bin/start-umbriel
        touch $out/share/systemd/user/umbriel.service
        touch $out/share/systemd/user/umbriel-session.target
        touch $out/share/systemd/user/umbriel-shutdown.target
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
    assertPathNotExists home-files/.config/umbriel/config.toml
    assertPathNotExists home-path/bin/umbriel
    assertPathNotExists home-path/bin/start-umbriel
    assertPathNotExists home-path/share/systemd/user/umbriel.service
    assertPathNotExists home-path/share/systemd/user/umbriel-session.target
    assertPathNotExists home-path/share/systemd/user/umbriel-shutdown.target
    assertPathNotExists home-path/share/xdg-desktop-portal/portals/umbriel.portal
    assertPathNotExists home-path/share/xdg-desktop-portal/umbriel-portals.conf
  '';
}
