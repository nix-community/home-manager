{ config, pkgs, ... }:

{
  config = {
    services.gammastep = {
      enable = true;
      provider = "manual";
      dawnTime = "6:00-7:45";
      duskTime = "18:35-20:15";
      settings = {
        general = {
          adjustment-method = "randr";
          gamma = 0.8;
        };
        randr = { screen = 0; };
      };
    };

    test.stubs.gammastep = { };

    nmt.script = ''
      assertFileContent \
          home-files/.config/gammastep/config.ini \
          ${./gammastep-basic-configuration-file-expected.conf}
      assertFileContent \
          home-files/.config/systemd/user/gammastep.service \
          ${./gammastep-basic-configuration-expected.service}
    '';
  };
}
