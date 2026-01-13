{ config, ... }:

{
  time = "2025-12-01T12:35:38+00:00";
  condition = config.services.ludusavi.enable;
  message = ''
    BREAKING CHANGE:

    The `ludusavi` module has changed its default backup and restore path.
    The new module implements a mechanism to automatically migrate the backups
    to the new path, but if it doesn't work and you can't find your backups in
    `ludusavi`, they should be in the old path: ~/\$XDG_STATE_HOME/backups/ludusavi/
    (that means a directory literally called $XDG_STATE_HOME in your home, rather than
    the env var expanded). For more info, see pull #8234.
  '';
}
