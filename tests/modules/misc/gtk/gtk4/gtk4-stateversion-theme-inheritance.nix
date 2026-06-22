{ pkgs, ... }:
{
  home.stateVersion = "25.11";

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
  };

  nmt.script = ''
    assertFileRegex home-files/.config/gtk-4.0/settings.ini \
      '^gtk-theme-name=Adwaita-dark$'
    assertFileContains home-files/.config/gtk-4.0/gtk.css \
      'share/themes/Adwaita-dark/gtk-4.0/gtk.css'
  '';
}
