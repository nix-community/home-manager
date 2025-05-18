{ config, ... }:
{
  config = {
    services.shikane = {
      enable = true;
      package = config.lib.test.mkStubPackage { };
      settings = {
        profile = [
          {
            name = "external-monitor-default";
            output = [
              {
                match = "eDP-1";
                enable = true;
              }
              {
                match = "HDMI-A-1";
                enable = true;
                position = {
                  x = 1920;
                  y = 0;
                };
              }
            ];
          }
          {
            name = "builtin";
            output = [
              {
                match = "eDP-1";
                enable = true;
              }
            ];
          }
        ];
      };
    };

    nmt.script = ''
      serviceFile=home-files/.config/systemd/user/shikane.service
      assertFileExists $serviceFile

      assertFileExists home-files/.config/shikane/config.toml
      assertFileContent home-files/.config/shikane/config.toml ${./expected.toml}
    '';
  };
}
