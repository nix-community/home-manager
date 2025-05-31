{ config, ... }:

{
  time = "2025-01-29T17:34:53+00:00";
  condition = config.programs.firefox.enable;
  message = ''
    The Firefox module now provides a
    'programs.firefox.profiles.<name>.preConfig' option.

    It allows extra preferences to be added to 'user.js' before the
    options specified in 'programs.firefox.profiles.<name>.settings', so
    that they can be overwritten.
  '';
}
