{ pkgs, ... }:
{
  gtk = {
    enable = true;
    theme = {
      name = "catppuccin-macchiato-blue-standard";
      package = pkgs.catppuccin-gtk;
    };
    gtk4 = {
      extraConfig = {
        gtk-cursor-blink = false;
        gtk-recent-files-limit = 20;
      };
    };
  };

  nmt.script =
    let
      gtk4Path = "home-files/.config/gtk-4.0";
    in
    ''
      assertFileExists ${gtk4Path}/settings.ini
      assertFileContent ${gtk4Path}/settings.ini \
        ${./gtk4-basic-settings-expected.ini}

      assertFileExists ${gtk4Path}/gtk.css
      assertFileContent ${gtk4Path}/gtk.css \
        ${./gtk4-basic-settings-expected.css}
    '';
}
