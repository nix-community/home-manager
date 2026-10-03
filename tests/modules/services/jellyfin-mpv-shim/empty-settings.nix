{ config, ... }:
{
  services.jellyfin-mpv-shim.enable = true;

  nmt.script =
    assert !(config.home.activation ? jellyfinMpvShimSettingsActivation);
    assert config.systemd.user.services.jellyfin-mpv-shim.Unit.X-Restart-Triggers == [ ];
    ''
      assertPathNotExists home-files/.config/jellyfin-mpv-shim
      assertFileNotRegex activate 'Merging Nix-generated config into .*jellyfin-mpv-shim'
    '';
}
