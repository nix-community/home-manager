{ config, ... }:
{
  time = "2026-05-15T18:12:18+00:00";
  condition = config.programs.ssh.enable;
  message = ''
    `programs.ssh` now supports RFC 42-style configuration through
    `programs.ssh.settings`. The existing `programs.ssh.matchBlocks`
    option is deprecated and automatically migrated to the new option.
  '';
}
