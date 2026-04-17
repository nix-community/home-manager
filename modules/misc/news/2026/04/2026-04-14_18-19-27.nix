{ config, ... }:
{
  time = "2026-04-14T12:49:27+00:00";
  condition = config.programs.yazi.enable;
  message = ''
    Added new option for yazi: programs.yazi.vfs

    Yazi provides a vfs.toml config file to manage virtual file systems,
    which can now be managed with programs.yazi.vfs
  '';
}
