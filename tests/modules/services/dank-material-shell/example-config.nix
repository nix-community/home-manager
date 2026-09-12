{
  programs.dank-material-shell = {
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
    assertFileExists home-files/.config/DankMaterialShell/settings.json
    assertFileContent home-files/.config/DankMaterialShell/settings.json \
    ${./settings.json}

    assertFileExists home-files/.local/state/DankMaterialShell/session.json
    assertFileContent home-files/.local/state/DankMaterialShell/session.json \
    ${./session.json}

    assertFileExists home-files/.config/DankMaterialShell/clsettings.json
    assertFileContent home-files/.config/DankMaterialShell/clsettings.json \
    ${./clsettings.json}
  '';
}
