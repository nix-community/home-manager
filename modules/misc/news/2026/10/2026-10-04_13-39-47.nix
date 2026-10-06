{ config, ... }:
{
  time = "2026-10-04T18:39:47+00:00";
  condition = config.programs.pet.enable;
  message = ''
    The Pet module now supports adding snippets alongside declared snippets
    through 'programs.pet.enableMutableSnippets'.

    When enabled, Home Manager loads declared snippets from a directory of
    read-only files and leaves the main snippet file writable for snippets
    added through Pet. Existing snippet directories are retained. Edit
    declared snippets through Home Manager; the configuration file remains
    read-only. This option requires Pet's 'snippetdirs' support and defaults
    to false.
  '';
}
