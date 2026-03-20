{
  time = "2025-02-07T22:31:45+00:00";
  condition = true;
  message = ''
    All 'programs.<PROGRAM>.enable<SHELL>Integration' values now default
    to the new 'home.shell.enable<SHELL>Integration' options, which
    inherit from the new the 'home.shell.enableShellIntegration' option.

    The following inconsistent default values change from 'false' to
    'true':

    - programs.zellij.enableBashIntegration
    - programs.zellij.enableFishIntegration
    - programs.zellij.enableZshIntegration
  '';
}
