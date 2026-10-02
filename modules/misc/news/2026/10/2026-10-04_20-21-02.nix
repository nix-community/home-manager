{ config, ... }:
{
  time = "2026-10-05T01:21:02+00:00";
  condition = config.services.colima.enable;
  message = ''
    Colima profiles now support `services.colima.profiles.<name>.mutableSettings`
    to merge declarative settings into writable configuration files during
    activation. Immutable configuration remains the default, and this option
    does not change the service's `--save-config` behavior.
  '';
}
