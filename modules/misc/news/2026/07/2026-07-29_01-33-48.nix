{ config, ... }:
{
  time = "2026-07-29T01:33:48+00:00";
  condition = config.services.syncthing.enable;
  message = ''
    `services.syncthing.settings` now uses partial REST updates for GUI, LDAP,
    and options. This preserves unspecified values in those objects, including
    the generated GUI API key.

    Removing a value from the Home Manager configuration no longer resets it
    in these objects. Set the desired default explicitly to reset a previously
    configured value. Folders and devices retain replacement semantics.
  '';
}
