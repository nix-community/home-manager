{
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    settings = {
      cursor = {
        enable_hyprcursor = true;
        sync_gsettings_theme = true;
      };
    };
  };

  test.asserts.warnings.expected = [''
    xdg-desktop-portal 1.17 reworked how portal implementations are loaded, you
    should either set `xdg.portal.config` or `xdg.portal.configPackages`
    to specify which portal backend to use for the requested interface.

    https://github.com/flatpak/xdg-desktop-portal/blob/1.18.1/doc/portals.conf.rst.in

    If you simply want to keep the behaviour in < 1.17, which uses the first
    portal implementation found in lexicographical order, use the following:

    xdg.portal.config.common.default = "*";
  ''];
  test.asserts.warnings.enable = true;

  nmt.script = ''
    config=home-files/.config/hypr/hyprland.conf
    assertFileExists "$config"
  '';
}
