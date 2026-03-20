{
  time = "2026-01-10T18:52:15+00:00";
  condition = true;
  message = ''
    A new module is available: `services.proton-pass-agent`

    This module allows you to use Proton Pass as a SSH agent, enabling secure
    storage and management of SSH keys through your Proton Pass vault.

    The service integrates with the usual shells (bash, zsh, fish, nushell) and
    provides options to:
    - Specify a vault or share ID to pull keys from
    - Configure automatic key refresh intervals
    - Enable automatic creation of new SSH key items when added via ssh-add

    The agent runs as a systemd user service on Linux and as a launchd agent
    on macOS, automatically setting the SSH_AUTH_SOCK environment variable.
  '';
}
