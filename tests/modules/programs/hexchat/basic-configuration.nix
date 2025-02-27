{
  programs.hexchat = {
    enable = true;
    overwriteConfigFiles = true;
    channels = {
      oftc = {
        charset = "UTF-8 (Unicode)";
        userName = "user";
        password = "password";
        loginMethod = "sasl";
        nickname = "user";
        nickname2 = "user_";
        realName = "real_user";
        options = {
          autoconnect = true;
          forceSSL = true;
        };
        servers = [ "irc.oftc.net" ];
        autojoin = [ "#home-manager" ];
      };
      efnet = {
        options = { forceSSL = true; };
        servers = [
          "irc.choopa.net"
          "irc.colosolutions.net"
          "irc.mzima.net"
          "irc.prison.net"
        ];
        autojoin = [ "#computers" ];
      };
    };
    settings = {
      dcc_dir = "/home/user/Downloads";
      irc_nick1 = "user";
      irc_nick2 = "user_";
      irc_nick3 = "user__";
      irc_user_name = "user";
      irc_real_name = "real user";
      text_font = "Monospace 14";
      text_font_main = "Monospace 14";
      gui_slist_skip = "1"; # Skip network list on start-up
      gui_quit_dialog = "0";
    };
  };

  nmt.script = ''
    assertFileContent \
       home-files/.config/hexchat/hexchat.conf \
       ${./basic-configuration-expected-main-config}
    assertFileContent \
       home-files/.config/hexchat/servlist.conf \
       ${./basic-configuration-expected-serverlist-config}
  '';
}
