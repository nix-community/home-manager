{ config, pkgs, ... }:

{
  config = {
    programs.autorandr = {
      enable = true;
      profiles = {
        default = {
          fingerprint = {
            DP1 = "XXX";
            DP2 = "YYY";
          };
          config = {
            DP1.enable = false;
            DP2 = {
              crtc = 0;
              primary = true;
              position = "0x0";
              mode = "1920x1080";
              scale = {
                x = 2;
                y = 4;
              };
              transform = [
                [ 0.6 0.0 0.0 ] # a b c
                [ 0.0 0.6 0.0 ] # d e f
                [ 0.0 0.0 1.0 ] # g h i
              ];
            };
          };
        };
      };
    };

    nmt.script = ''
      config=home-files/.config/autorandr/default/config
      setup=home-files/.config/autorandr/default/setup

      assertFileExists $setup
      assertFileRegex $setup 'DP1 XXX'
      assertFileRegex $setup 'DP2 YYY'

      assertFileExists $config
      assertFileContent $config \
          ${./basic-configuration.conf}
    '';
  };
}
