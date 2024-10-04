{ pkgs, config, ... }:
{
  time = "2025-04-26T13:26:13+00:00";
  condition = pkgs.hostPlatform.isLinux && config.services.espanso.enable;
  message = ''
    `services.espanso` now supports wayland.
    This is enabled by default on Linux as `services.espanso.waylandSupport = true;`.
    Depending on your graphical session type, you may disable one of `services.espanso.x11Support` and `services.espanso.waylandSupport` to reduce the closure size of espanso on your system.
    Both x11 and wayland versions come enabled by default on Linux.
  '';
}
