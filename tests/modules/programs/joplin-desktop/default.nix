{
  joplin-desktop-no-settings = ./no-settings.nix;
  joplin-desktop-omitted-settings = ./omitted-settings.nix;
  joplin-desktop-basic-configuration = ./basic-configuration.nix;
  joplin-desktop-legacy-configuration = ./legacy-configuration.nix;
  joplin-desktop-legacy-editor-conditional = import ./legacy-editor-conditional.nix "vim";
  joplin-desktop-legacy-editor-conditional-unset = import ./legacy-editor-conditional.nix null;
  joplin-desktop-extra-config-root-force = ./extra-config-root-force.nix;
  joplin-desktop-legacy-unset = ./legacy-unset.nix;
  joplin-desktop-root-force = ./root-force.nix;
}
