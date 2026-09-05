{ config, ... }:
{
  time = "2026-08-27T12:30:00+00:00";
  condition = config.home.sessionPath != [ ] || config.home.sessionSearchVariables != { };
  message = ''
    Search-path style session variables are now merged instead of
    concatenated. An entry already present in the inherited value is not
    duplicated. Statically empty entries produce a warning, and all entries
    that expand to an empty string are dropped.

    If you used an empty entry to mean "the current directory", write `.`
    instead. If you used a trailing separator so that a tool such as `man`
    splices in its own system default, set that variable through
    {option}`home.sessionVariables`, which is still emitted verbatim.
  '';
}
