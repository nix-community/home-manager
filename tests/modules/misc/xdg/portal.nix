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
    assertFileExists home-path/share/systemd/user/xdg-desktop-portal.service
    assertFileExists home-path/share/systemd/user/xdg-desktop-portal-wlr.service
    assertFileExists home-path/share/systemd/user/xdg-desktop-portal-hyprland.service

    assertFileContent home-path/share/xdg-desktop-portal/portals/hyprland.portal \
      ${pkgs.xdg-desktop-portal-hyprland}/share/xdg-desktop-portal/portals/hyprland.portal
    assertFileContent home-path/share/xdg-desktop-portal/portals/wlr.portal \
      ${pkgs.xdg-desktop-portal-wlr}/share/xdg-desktop-portal/portals/wlr.portal

    assertFileContent home-path/share/xdg-desktop-portal/hyprland-portals.conf \
      ${pkgs.hyprland}/share/xdg-desktop-portal/hyprland-portals.conf
    assertFileContent home-files/.config/xdg-desktop-portal/sway-portals.conf \
      ${./sway-portals-expected.conf}
  '';
}
