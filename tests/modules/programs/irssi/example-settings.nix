{ config, ... }:

{
  programs.irssi = {
    enable = true;
    networks.oftc = {
      nick = "nick";
      saslExternal = true;
      server = {
        address = "irc.oftc.net";
        port = 6697;
        autoConnect = true;
        ssl.certificateFile =
          "${config.home.homeDirectory}/.irssi/certs/nick.pem";
      };
      channels.home-manager.autoJoin = true;
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/.irssi/config \
      ${./example-settings-expected.config}
  '';
}
