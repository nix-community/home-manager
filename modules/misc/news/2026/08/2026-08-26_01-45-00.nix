{ config, ... }:
{
  time = "2026-08-26T01:45:00+00:00";
  condition = config.services.voxtype.enable;
  message = ''
    The `voxtype` daemon now starts as part of `graphical-session.target`
    instead of `default.target`. This orders the service after the compositor
    has taken ownership of the GPU render node, so a Vulkan-accelerated
    whisper build can find its device instead of falling back to CPU.

    Sessions that never activate `graphical-session.target` (for example a
    bare `startx` without a session manager) will no longer auto-start
    `voxtype`. If you rely on that, add `voxtype` to
    {option}`systemd.user.startServices` or start it manually after login.
  '';
}
