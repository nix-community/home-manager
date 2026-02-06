{ lib, ... }:

{
  wayland.windowManager.niri = {
    enable = true;

    # Disabling package should not add niri to the `$PATH`
    package = null;

    # Disabling systemd and portal should not link the files
    portalPackage = null;
    systemd.enable = false;
    xwaylandSatellite = null;

    # Empty Config should not generate `$XDG_CONFIG_HOME/niri/config.kdl`
    extraConfigEarly = "";
    extraConfig = "";
    settings = {
      _children = [ ];
    };
  };

  # Stubs with `outPath = null` produce real derivations so that the negative
  # assertions below are meaningful. Without them, scrubbed packages can never
  # be linked by `buildEnv` and the assertions would trivially pass even if the
  # module incorrectly added them to `home.packages`.
  test.stubs = {
    niri = {
      outPath = null;
      buildScript = ''
        mkdir -p $out/bin $out/share/systemd/user $out/share/xdg-desktop-portal

        touch $out/bin/niri
        touch $out/bin/niri-session
        touch $out/share/systemd/user/niri.service
        touch $out/share/systemd/user/niri-shutdown.target
        touch $out/share/xdg-desktop-portal/niri-portals.conf
      '';
    };
    xwayland-satellite = {
      outPath = null;
      buildScript = ''
        mkdir -p $out/bin
        touch $out/bin/xwayland-satellite
      '';
    };
    xdg-desktop-portal-gnome = {
      outPath = null;
      buildScript = ''
        mkdir -p $out/share/xdg-desktop-portal/portals
        touch $out/share/xdg-desktop-portal/portals/gnome.portal
      '';
    };
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/niri/config.kdl
    assertPathNotExists home-path/bin/niri
    assertPathNotExists home-path/bin/niri-session
    assertPathNotExists home-path/bin/xwayland-satellite
    assertPathNotExists home-path/share/systemd/user/niri.service
    assertPathNotExists home-path/share/systemd/user/niri-shutdown.target
    assertPathNotExists home-path/share/xdg-desktop-portal/niri-portals.conf
    assertPathNotExists home-path/share/xdg-desktop-portal/portals/gnome.portal
  '';
}
