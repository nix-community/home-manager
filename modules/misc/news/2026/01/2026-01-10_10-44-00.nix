{ config, ... }:
{
  time = "2026-01-10T10:44:00+00:00";
  condition = config.programs.fresh-editor.enable;
  message = ''

    A new module is available: 'programs.fresh-editor'

    Fresh is a terminal-based text editor: easy, powerful and fast. It is
    engineered for speed. It delivers a low-latency experience, with text
    appearing instantly. The editor is designed to be light and fast, reliably
    opening and editing huge files up to multi-gigabyte sizes without slowdown.
  '';
}
