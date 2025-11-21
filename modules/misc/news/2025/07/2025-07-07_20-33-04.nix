{ config, ... }:
{
  time = "2025-07-07T18:33:04+00:00";
  condition = config.programs.thunderbird.enable;
  message = ''
    'programs.thunderbird' now supports declaration of address books using
    'accounts.contact.accounts'.
  '';
}
