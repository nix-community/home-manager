{ config, ... }: {
  programs.pomo = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
    settings = {
      onSessionEnd = "ask";
      asciiArt = {
        enabled = true;
        font = "mono12";
        color = "#5A56E0";
      };
      work = {
        duration = "25m";
        title = "work session";
        notification = {
          enabled = true;
          urgent = false;
          title = "work finished 🎉";
          message = "time to take a break";
        };
      };
      break = {
        duration = "5m";
        title = "break session";
        notification = {
          enabled = true;
          urgent = false;
          title = "break over 😴";
          message = "back to work!";
        };
      };
      longBreak = {
        enabled = true;
        after = 4;
        duration = "20m";
      };
    };
  };
  nmt.script = ''
    local configFile=home-files/.config/pomo/pomo.yaml

    assertFileExists $configFile
    assertFileContent $configFile ${./example-settings-expected.yaml}
  '';
}
