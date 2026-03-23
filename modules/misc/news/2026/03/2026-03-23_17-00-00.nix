{ config, ... }:
{
  time = "2026-03-23T17:00:00+00:00";
  condition = config.programs.feedr.enable;
  message = ''

    A new module is available: 'programs.feedr'

    Feedr is a modern terminal-based RSS/Atom feed reader with advanced
    filtering, categorization, and search capabilities. It supports both RSS and
    Atom feeds with compression handling and provides an intuitive TUI
    interface.
  '';
}
