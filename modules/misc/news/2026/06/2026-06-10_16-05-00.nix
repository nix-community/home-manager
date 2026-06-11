{ config, ... }:
{
  time = "2026-06-10T16:05:00+00:00";
  condition = config.programs.difftastic.enable;
  message = ''
    The git integration of 'programs.difftastic' now uses a new option
    'programs.difftastic.git.mode' to select how difftastic is wired into
    git:

    - "external" (default): set 'diff.external' so 'git diff' uses
      difftastic.
    - "difftool": only configure difftastic as a git difftool, leaving
      'git diff' untouched.
    - "both": configure both.

    The boolean option 'programs.difftastic.git.diffToolMode' is deprecated;
    existing configurations are migrated automatically ('true' becomes
    "both" and 'false' becomes "external").
  '';
}
