{
  programs.dux-shell = {
    enable = true;

    settings = {
      theme = "dark";
      dynamicTheming = true;
    };

    session = {
      isLightMode = false;
    };

    clipboardSettings = {
      maxHistory = 25;
      maxEntrySize = 5242880;
      autoClearDays = 1;
      clearAtStartup = true;
      disabled = false;
      disableHistory = false;
      disablePersist = true;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/DuxShell/settings.json
    assertFileContent home-files/.config/DuxShell/settings.json \
    ${./settings.json}

    assertFileExists home-files/.local/state/DuxShell/session.json
    assertFileContent home-files/.local/state/DuxShell/session.json \
    ${./session.json}

    assertFileExists home-files/.config/DuxShell/clsettings.json
    assertFileContent home-files/.config/DuxShell/clsettings.json \
    ${./clsettings.json}
  '';
}
