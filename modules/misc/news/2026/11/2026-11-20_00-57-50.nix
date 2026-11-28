{ config, ... }:
{
  time = "2026-11-20T00:57:50+00:00";
  condition = config.services.ssh-agent.enable;
  message = ''
    The `services.ssh-agent` module now supports askpass integration via
    `services.ssh-agent.askpass`.

    When specified and pointed to an askpass binary of your choice, it allows
    the ssh-agent to accept a pin or passphrase as needed e.g. when decrypting
    SSH keys or unlocking FIDO2/U2F hardware security keys.
  '';
}
