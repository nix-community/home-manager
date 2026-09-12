{ config, ... }:
{
  time = "2026-09-11T00:00:00+00:00";
  condition = config.programs.joplin-desktop.enable;
  message = ''
    Joplin Desktop now supports freeform JSON configuration through
    `programs.joplin-desktop.settings`. This replaces
    `programs.joplin-desktop.extraConfig`,
    `programs.joplin-desktop.general.editor`,
    `programs.joplin-desktop.sync.target`, and
    `programs.joplin-desktop.sync.interval`.

    Use literal dotted keys and numeric sync values, for example
    `programs.joplin-desktop.settings."sync.target" = 7` and
    `programs.joplin-desktop.settings."sync.interval" = 600`
    for Dropbox synchronization every ten minutes.

    Activation still merges settings into Joplin's writable file and preserves
    unmanaged settings. Top-level null and empty strings remain omitted.
  '';
}
