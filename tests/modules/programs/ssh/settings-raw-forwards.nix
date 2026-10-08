{ config, lib, ... }:
{
  config = {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings.raw = {
        LocalForward = "9000 10.0.0.2:90";
        RemoteForward = [ "9001 10.0.0.3:91" ];
        DynamicForward = "127.0.0.1:1080";
      };
    };

    home.file.assertions.text = builtins.toJSON (
      map (a: a.message) (lib.filter (a: !a.assertion) config.assertions)
    );

    nmt.script = ''
      assertFileExists home-files/.ssh/config
      assertFileContent \
        home-files/.ssh/config \
        ${./settings-raw-forwards-expected.conf}
      assertFileContent home-files/assertions ${./no-assertions.json}
    '';
  };
}
