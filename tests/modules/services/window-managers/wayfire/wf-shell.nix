{
  wayland.windowManager.wayfire = {
    enable = true;
    package = null;
    wf-shell = {
      enable = true;
      settings = {
        panel = {
          widgets_left = "menu spacing4 launchers window-list";
          autohide = true;
        };
      };
    };
  };

  nmt.script = ''
    wfShellConfig=home-files/.config/wf-shell.ini

    assertFileExists "$wfShellConfig"
    assertFileContent "$wfShellConfig" "${./wf-shell.ini}"
  '';
}
