{
  waybar-systemd-with-graphical-session-target =
    ./systemd-with-graphical-session-target.nix;
  waybar-styling = ./styling.nix;
  waybar-settings-complex = ./settings-complex.nix;
  # Broken configuration from https://github.com/nix-community/home-manager/pull/1329#issuecomment-653253069
  waybar-broken-settings = ./broken-settings.nix;
}
