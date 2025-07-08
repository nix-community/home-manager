{
  programs.twitch-tui = {
    enable = true;
    settings = {
      twitch = {
        username = "";
        channel = "";
        server = "wss://eventsub.wss.twitch.tv/ws";
        token = "";
      };

      terminal = {
        delay = 30;
        maximum_messages = 500;
        log_file = "";
        log_level = "info";
        first_state = "dashboard";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/twt/config.toml
    assertFileContent home-files/.config/twt/config.toml \
    ${./config.toml}
  '';
}
