{ config, pkgs, ... }:
{
  time = "2025-11-03T21:56:50+00:00";
  condition = config.programs.ghostty.enable && pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    Ghostty:  now enables the user systemd service by default.

    Running Ghostty via these systemd units is the recommended way to run
    Ghostty. The two most important benefits provided by Ghostty's systemd
    integrations are: instantaneous launching and centralized logging.

    See https://ghostty.org/docs/linux/systemd for all details
  '';
}
