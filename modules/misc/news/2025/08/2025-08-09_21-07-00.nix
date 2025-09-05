{ pkgs, ... }:
{
  time = "2025-08-09T22:11:00+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new service is available: 'services.pizauth'.

    Pizauth is a simple program for requesting, showing, and refreshing OAuth2 access tokens.
    Pizauth is formed of two components: a persistent server which interacts with the user to request tokens, and refreshes them as necessary;
    and a command-line interface which can be used by programs such as fdm and msmtp to authenticate with OAuth2.
  '';
}
