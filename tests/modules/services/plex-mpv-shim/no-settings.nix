{
  enable,
  mutableSettings ? false,
}:
{ config, lib, ... }:
{
  services.plex-mpv-shim = {
    inherit enable mutableSettings;
    settings = lib.optionalAttrs (!enable) { auto_play = true; };
  };

  nmt.script =
    assert !(config.home.activation ? plexMpvShimSettingsActivation);
    ''
      assertPathNotExists home-files/.config/plex-mpv-shim/conf.json
      assertFileNotRegex activate 'plexMpvShimSettingsActivation|plex-mpv-shim-conf.json'
    ''
    + lib.optionalString enable ''
      assertFileNotRegex home-files/.config/systemd/user/plex-mpv-shim.service 'X-Restart-Triggers'
    '';
}
