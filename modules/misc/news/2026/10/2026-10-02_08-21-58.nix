{ config, ... }:
{
  time = "2026-10-02T08:21:58+00:00";
  condition =
    config.programs.github-copilot-cli.enable && config.programs.github-copilot-cli.settings != { };
  message = ''
    The option 'programs.github-copilot-cli.settings' is now written to
    settings.json instead of config.json. Copilot CLI 1.0.35 and later read
    user settings from settings.json and keep internal state in config.json,
    moving declared settings out of a linked config.json and replacing the
    link, which caused collisions on later activations. The old config.json
    link is removed automatically if it still points to a Home Manager
    generation; a regular file left by Copilot CLI stays for it to manage.

    If Copilot CLI already moved your settings into a regular settings.json,
    remove that file before switching. Otherwise activation reports it as a
    collision, or leaves it unmanaged when its content happens to match.

    'trusted_folders' and 'trustedFolders' are no longer written, since
    Copilot CLI keeps trusted folders in its own state. Trust folders from
    Copilot CLI instead.
  '';
}
