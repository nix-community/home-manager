{ config, ... }:

{
  time = "2024-03-14T07:22:09+00:00";
  condition = config.services.gpg-agent.enable;
  message = ''

    'services.gpg-agent.pinentryFlavor' has been removed and replaced by
    'services.gpg-agent.pinentryPackage'.
  '';
}
