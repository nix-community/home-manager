{ config, ... }:
{
  time = "2025-12-10T07:15:59+00:00";
  condition = config.programs.firefox.enable;
  message = ''
    The Firefox module now provides a
    'programs.firefox.profiles.<name>.handlers' option.

    It allows declarative configuration of MIME type and URL scheme handlers
    through Firefox's handlers.json file, controlling how Firefox opens files
    and protocols (e.g., PDF viewers, mailto handlers).

    Configure handlers with:

      programs.firefox.profiles.<name>.handlers.mimeTypes
      programs.firefox.profiles.<name>.handlers.schemes
  '';
}
