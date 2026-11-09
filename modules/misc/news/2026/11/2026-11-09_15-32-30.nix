{ config, ... }:
{
  time = "2026-11-09T21:32:30+00:00";
  condition = config.programs.thunderbird.enable;
  message = ''
    Thunderbird contact accounts now support additional preferences through
    'accounts.contact.accounts.<name>.thunderbird.settings'. This function
    receives the generated contact identifier, allowing settings such as the
    CardDAV synchronization interval to be configured.
  '';
}
