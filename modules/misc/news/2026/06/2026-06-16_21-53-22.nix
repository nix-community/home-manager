{ config, ... }:
{
  time = "2026-06-16T19:53:22+00:00";
  condition = config.programs.git-credential-keepassxc.enable;
  # if behavior changed, explain how to restore previous behavior.
  message = ''
    'programs.git-credential-keepassxc.unlock' was added
    to automatically ask for a login when required.
  '';
}
