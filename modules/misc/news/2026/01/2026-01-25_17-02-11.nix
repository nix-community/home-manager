{ config, ... }:
{
  time = "2026-01-25T17:02:11+00:00";
  condition = config.services.syncthing.enable;
  message = ''
    The `services.syncthing.passwordFile` option has been removed, as
    configuring it would not add any authentication requirements to the
    Syncthing GUI, but in most circumstances would suppress the warnings about
    the GUI not being secured.

    Instead, configure `services.syncthing.guiCredentials.passwordFile` and
    `services.syncthing.guiCredentials.username`.

    As a benefit, using `services.syncthing.guiCredentials` will only change
    the Syncthing login configuration if credentials have actually changed,
    rather than configuring them unconditionally.  This prevents the Syncthing
    API key from changing unnecessarily, so other tools such as Syncthing Tray
    do not need to reconfigure the API key as often.
  '';
}
