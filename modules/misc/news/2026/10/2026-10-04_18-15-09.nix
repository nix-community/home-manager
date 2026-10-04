{ config, pkgs, ... }:
{
  time = "2026-10-04T05:15:09+00:00";
  condition = config.services.proton-pass-agent.enable && pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    The Proton Pass SSH agent now keeps trying to start when no
    'pass-cli login' has been made. It retries every 10 seconds instead
    of stopping after systemd's start rate limit, so the agent becomes
    available on its own after you log in. Previously the service had to
    be restarted manually.
  '';
}
