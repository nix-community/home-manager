{ config, ... }:
{
  time = "2026-09-21T00:00:00+00:00";
  condition = config.programs.notmuch.enable;
  message = ''
    The notmuch module now writes native INI keys from
    `programs.notmuch.settings`, including semicolon-separated lists.
    `programs.notmuch.new.ignore`, `programs.notmuch.new.tags`,
    `programs.notmuch.maildir.synchronizeFlags`,
    `programs.notmuch.search.excludeTags`, and `programs.notmuch.extraConfig`
    are deprecated aliases and warn when used. Home Manager leaves the
    `new.tags`, `new.ignore`, and `maildir.synchronize_flags` settings to
    notmuch's defaults. For `home.stateVersion` below 26.11,
    `search.exclude_tags` defaults to `deleted;spam`, and `database.path` is
    set even without email accounts. Unlike the previous `extraConfig`
    overlay, definitions follow module priorities: ordinary scalar collisions
    conflict, lists concatenate, and forced values win.
  '';
}
