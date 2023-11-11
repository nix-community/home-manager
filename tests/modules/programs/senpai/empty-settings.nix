{ config, ... }:

{
  config = {
    programs.senpai = {
      enable = true;
      package = config.lib.test.mkStubPackage { };
      config = {
        address = "irc.libera.chat";
        nickname = "Guest123456";
      };
    };

    nmt.script = ''
      assertFileContent \
        home-files/.config/senpai/senpai.scfg \
        ${./empty-settings-expected.conf}
    '';
  };
}
