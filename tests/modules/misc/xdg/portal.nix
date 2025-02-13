{ config, lib, realPkgs, ... }:

lib.mkIf config.test.enableBig {
  xdg.portal = {
    enable = true;
    extraPortals =
      [ realPkgs.xdg-desktop-portal-hyprland realPkgs.xdg-desktop-portal-wlr ];
    configPackages = [ realPkgs.hyprland ];
    config = { sway.default = [ "wlr" "gtk" ]; };
  };

  test.unstubs = [ (self: super: { inherit (realPkgs) xdg-desktop-portal; }) ];

  nmt.script = ''
    assertFileExists home-path/share/systemd/user/xdg-desktop-portal.service
    assertFileExists home-path/share/systemd/user/xdg-desktop-portal-wlr.service
    assertFileExists home-path/share/systemd/user/xdg-desktop-portal-hyprland.service

    assertFileContent home-path/share/xdg-desktop-portal/portals/hyprland.portal \
      ${realPkgs.xdg-desktop-portal-hyprland}/share/xdg-desktop-portal/portals/hyprland.portal
    assertFileContent home-path/share/xdg-desktop-portal/portals/wlr.portal \
      ${realPkgs.xdg-desktop-portal-wlr}/share/xdg-desktop-portal/portals/wlr.portal

    assertFileContent home-path/share/xdg-desktop-portal/hyprland-portals.conf \
      ${realPkgs.hyprland}/share/xdg-desktop-portal/hyprland-portals.conf
    assertFileContent home-files/.config/xdg-desktop-portal/sway-portals.conf \
      ${./sway-portals-expected.conf}
  '';
}
