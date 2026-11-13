{ config, ... }:

{
  programs.t3code = {
    enable = true;
    package = null;
    mutableUserSettings = false;
    mutableKeybindings = false;
    mutableClientSettings = false;
    userSettings.enableAssistantStreaming = true;
    keybindings = [
      {
        key = "mod+j";
        command = "terminal.toggle";
      }
    ];
    clientSettings.settings.timestampFormat = "locale";
  };

  home.file.".t3/userdata/settings.json".enable = false;
  home.file.".t3/userdata/keybindings.json".enable = false;
  home.file.".t3/userdata/client-settings.json".enable = false;

  nmt.script =
    assert !(config.home.activation ? t3codeImmutableConfig);
    ''
      assertPathNotExists "home-files/.t3"
    '';
}
