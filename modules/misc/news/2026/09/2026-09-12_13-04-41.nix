{ config, ... }:
{
  time = "2026-09-12T05:04:41+00:00";
  condition = config.services.linux-wallpaperengine.enable;
  message = ''
    The global option 'services.linux-wallpaperengine.clamping' has been deprecated, please use the per-wallpaper option 'services.linux-wallpaperengine.wallpapers.*.clamp' instead.

    A new option is available: 'services.linux-wallpaperengine.fps'

    This fixes the incorrect behaviour as `linux-wallpaperengine` only supports setting fps globally.

    A new option is available: 'services.linux-wallpaperengine.audio'

    This fixes the incorrect behaviour as `linux-wallpaperengine` only supports setting audio options globally.

    A new option is available: 'services.linux-wallpaperengine.extraOptions'

    This allows passing other global options to the generated `linux-wallpaperengine` command.

    The per-wallpaper option 'services.linux-wallpaperengine.wallpapers.*.fps' has been deprecated, please use the global option 'services.linux-wallpaperengine.fps' instead.

    The per-wallpaper option 'services.linux-wallpaperengine.wallpapers.*.audio' has been deprecated, please use the global option 'services.linux-wallpaperengine.audio' instead.
  '';
}
