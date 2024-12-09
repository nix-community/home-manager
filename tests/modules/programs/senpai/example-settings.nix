{ config, ... }:

{
  config = {
    programs.senpai = {
      enable = true;
      package = config.lib.test.mkStubPackage { };
      config = {
        address = "irc.libera.chat";
        nickname = "Guest123456";
        password-cmd = [ "gopass" "show" "irc/guest" ];
        username = "senpai";
        realname = "Guest von Lenon";
        channel = [ "#rahxephon" ];
        highlight = [ "guest" "senpai" "lenon" ];
        pane-widths = { nicknames = 16; };
        colors = { prompt = 2; };
      };
    };

    nmt.script = ''
      assertFileContent \
        home-files/.config/senpai/senpai.scfg \
        ${./example-settings-expected.conf}
    '';
  };
}
