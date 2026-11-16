{ config, ... }:
{
  services.jellyfin-mpv-shim.settings.player_name = "disabled";

  nmt.script =
    assert !(config.home.activation ? jellyfinMpvShimSettingsActivation);
    assert !(config.systemd.user.services ? jellyfin-mpv-shim);
    ''
      assertPathNotExists home-files/.config/jellyfin-mpv-shim
      assertPathNotExists home-files/.config/systemd/user/jellyfin-mpv-shim.service
    '';
}
