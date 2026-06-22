{ config, ... }:
{
  time = "2026-04-23T18:35:00+00:00";
  condition = config.programs.firefox.enable;
  message = ''
    The deprecated `programs.firefox.profiles.<name>.extensions = [ ... ]`
    shorthand has been removed.

    Use `programs.firefox.profiles.<name>.extensions.packages = [ ... ]`
    to install add-ons, and keep declarative extension settings under
    `programs.firefox.profiles.<name>.extensions.settings`.
  '';
}
