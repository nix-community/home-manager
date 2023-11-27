{ config, lib, pkgs, ... }:

lib.mkIf config.test.enableBig {
  xdg.portal = {
    enable = true;
    extraPortals =
      [ pkgs.xdg-desktop-portal-hyprland pkgs.xdg-desktop-portal-wlr ];
    configPackages = [ pkgs.hyprland ];
    config = { sway.default = [ "wlr" "gtk" ]; };
  };

  nmt.script = ''
    xdgDesktopPortal=home-files/.config/systemd/user/xdg-desktop-portal.service
    assertFileExists $xdgDesktopPortal

    xdgDesktopPortalWlr=home-path/share/systemd/user/xdg-desktop-portal-wlr.service
    assertFileExists $xdgDesktopPortalWlr

    xdgDesktopPortalHyprland=home-path/share/systemd/user/xdg-desktop-portal-hyprland.service
    assertFileExists $xdgDesktopPortalHyprland

    portalsDir="$(cat $TESTED/$xdgDesktopPortal | grep Environment=XDG_DESKTOP_PORTAL_DIR | cut -d '=' -f3)"
    portalConfigsDir="$(cat $TESTED/$xdgDesktopPortal | grep Environment=NIXOS_XDG_DESKTOP_PORTAL_CONFIG_DIR | cut -d '=' -f3)"

    assertFileContent $portalsDir/hyprland.portal \
      ${pkgs.xdg-desktop-portal-hyprland}/share/xdg-desktop-portal/portals/hyprland.portal

    assertFileContent $portalsDir/wlr.portal \
      ${pkgs.xdg-desktop-portal-wlr}/share/xdg-desktop-portal/portals/wlr.portal

    assertFileContent $portalConfigsDir/hyprland-portals.conf \
      ${pkgs.hyprland}/share/xdg-desktop-portal/hyprland-portals.conf

    assertFileContent $portalConfigsDir/sway-portals.conf \
      ${./sway-portals-expected.conf}
  '';
}
