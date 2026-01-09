{ config, ... }:
{
  time = "2026-01-09T23:16:48+00:00";
  condition = config.services.ssh-agent.enable;
  message = ''
    There is a new 'services.ssh-agent.pkcs11Whitelist' option to whitelist
    PKCS#11 and FIDO authenticators.
  '';
}
