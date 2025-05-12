{ config, ... }:

{
  time = "2023-03-16:12:00+00:00";
  condition = config.programs.i3status-rust.enable;
  message = ''

    Module 'i3status-rust' was updated to support the new configuration
    format from 0.30.x releases, that introduces many breaking changes.
    The documentation was updated with examples from 0.30.x to help
    the transition.

    See https://github.com/greshake/i3status-rust/blob/v0.30.0/NEWS.md
    for instructions on how to migrate.

    Users that don't want to migrate yet can set
    'programs.i3status-rust.package' to an older version.
  '';
}
