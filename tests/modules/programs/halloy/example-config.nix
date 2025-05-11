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
  };

  nmt.script = ''
    assertFileExists home-files/.config/halloy/config.toml
    assertFileContent home-files/.config/halloy/config.toml \
    ${./example-config.toml}
  '';
}
