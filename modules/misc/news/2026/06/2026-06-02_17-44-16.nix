{ config, ... }:
{
  time = "2026-06-02T15:44:16+00:00";
  condition =
    config.services.gpg-agent.enable
    || config.services.proton-pass-agent.enable
    || config.services.ssh-agent.enable
    || config.services.ssh-tpm-agent.enable
    || config.services.yubikey-agent.enable;
  message = ''
    A new module is available: 'sshAuthSock'.

    It takes care of setting the `SSH_AUTH_SOCK` environment variable
    properly and is implicitly enabled and configured by SSH agent modules.
    You can use the 'sshAuthSock.systemd.socketProviderUnit' option to make
    SSH agents accessible to systemd-managed applications.
  '';
}
