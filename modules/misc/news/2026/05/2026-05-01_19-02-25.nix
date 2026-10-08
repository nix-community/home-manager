{
  time = "2026-05-01T18:02:25+00:00";
  condition = true;
  message = ''
    Two new module are available: 'programs.man.man-db' and
    'programs.man.mandoc'.

    They allow selecting the default man page viewer. man-db was the default
    man page viewer before those changes, so
    'programs.man.man-db.enable = true' set by default.

    Since the options conflict between each other, to enable mandoc you need to
    set 'programs.man.man-db.enable = false' and
    'program.man.mandoc.enable = true'.
  '';
}
