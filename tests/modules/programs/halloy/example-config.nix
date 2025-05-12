{
  programs.halloy = {
    enable = true;
    settings = {
      buffer.channel.topic.enabled = true;
      servers.liberachat = {
        nickname = "halloy-user";
        server = "irc.libera.chat";
        channels = [ "#halloy" ];
      };
    };
    themes.my-theme = {
      general = {
        background = "<string>";
        border = "<string>";
        horizontal_rule = "<string>";
        unread_indicator = "<string>";
      };
      text = {
        primary = "<string>";
        secondary = "<string>";
        tertiary = "<string>";
        success = "<string>";
        error = "<string>";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/halloy/config.toml
    assertFileContent home-files/.config/halloy/config.toml \
      ${./example-config.toml}
    assertFileExists home-files/.config/halloy/themes/my-theme.toml
    assertFileContent home-files/.config/halloy/themes/my-theme.toml \
      ${./my-theme.toml}
  '';
}
