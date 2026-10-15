{ config, ... }:
{
  time = "2026-10-15T00:00:00+00:00";
  condition = config.programs.vicinae.enable;
  message = ''
    The vicinae module now supports Darwin and can be enabled to run as a
    launchd agent.

    Its service options have moved accordingly:
    `programs.vicinae.systemd.enable` and `programs.vicinae.systemd.autoStart`
    are deprecated aliases of `programs.vicinae.service.enable` and
    `programs.vicinae.service.autoStart`. `programs.vicinae.systemd.target`
    remains Linux-only.
  '';
}
