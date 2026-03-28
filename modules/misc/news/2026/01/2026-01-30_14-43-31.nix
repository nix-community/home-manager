{ config, ... }:
{
  time = "2026-01-30T14:43:31+00:00";
  condition = config.services.mako ? extraConfig;
  message = ''
    The option 'services.mako.extraConfig' has been removed, please use
    'services.mako.settings.include' instead.

    The 'services.mako.settings.include' option expects either a single file
    path, or a list of file paths.
  '';
}
