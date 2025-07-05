{
  gtk-global-inheritance = ./gtk-global-inheritance.nix;
  gtk-per-version-override = ./gtk-per-version-override.nix;
  gtk-selective-enable = ./gtk-selective-enable.nix;

  # GTK2
  gtk2-basic-config = ./gtk2/gtk2-basic-config.nix;
  gtk2-config-file-location = ./gtk2/gtk2-config-file-location.nix;

  # GTK3
  gtk3-basic-settings = ./gtk3/gtk3-basic-settings.nix;

  # GTK4
  gtk4-basic-settings = ./gtk4/gtk4-basic-settings.nix;
  gtk4-theme-css-injection = ./gtk4/gtk4-theme-css-injection.nix;
  gtk4-no-theme-css-injection = ./gtk4/gtk4-no-theme-css-injection.nix;
}
