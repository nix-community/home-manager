{
  programs.zapfast = {
    enable = true;
    package = null;
    settings = {
      theme = "dark";
      notifications = {
        enabled = true;
        sound = false;
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/zapfast/settings.json
    assertFileContent home-files/.config/zapfast/settings.json \
      ${./settings.json}
  '';
}
