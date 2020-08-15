{
  waybar-systemd-with-sway-session-target =
    ./systemd-with-sway-session-target.nix;
  waybar-systemd-with-cage-session-target =
    ./systemd-with-cage-session-target.nix;
  waybar-styling = ./styling.nix;
  waybar-settings-complex = ./settings-complex.nix;
  # Broken configuration from https://github.com/rycee/home-manager/pull/1329#issuecomment-653253069
  waybar-broken-settings = ./broken-settings.nix;
}
