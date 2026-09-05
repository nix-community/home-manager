{ config, ... }:
{
  time = "2026-08-27T13:00:00+00:00";
  condition = config.home.sessionSearchVariablesAppend != { };
  message = ''
    A new option {option}`home.sessionSearchVariablesAppend` adds entries after
    the inherited value of a PATH-like environment variable. On the first
    merge in a process tree, configured entries are repositioned according to
    the prepend or append option. Later merges preserve existing positions.

    `lib.mkAfter` cannot express this: it orders configured entries relative
    to each other, but cannot place one after the value inherited at runtime,
    which is what a fallback needs.
  '';
}
