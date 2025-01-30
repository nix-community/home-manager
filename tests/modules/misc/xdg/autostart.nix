{ pkgs, ... }: {
  config = {
    xdg.autostart = {
      enable = true;
      entries = [
        "${pkgs.evolution}/share/applications/org.gnome.Evolution.desktop"
        "${pkgs.tdesktop}/share/applications/org.telegram.desktop.desktop"
      ];
    };

    nmt.script = ''
      assertFileExists home-files/.config/autostart/org.gnome.Evolution.desktop
      assertFileContent home-files/.config/autostart/org.gnome.Evolution.desktop \
        ${pkgs.evolution}/share/applications/org.gnome.Evolution.desktop
      assertFileExists home-files/.config/autostart/org.telegram.desktop.desktop
      assertFileContent home-files/.config/autostart/org.telegram.desktop.desktop \
        ${pkgs.tdesktop}/share/applications/org.telegram.desktop.desktop
    '';
  };
}
