{ config, pkgs, ... }:

{
  config = {
    programs.autorandr = {
      enable = true;
      profiles = {
        default = {
          fingerprint.DP1 = "XXX";
          config.DP1 = {
            scale = {
              x = 2;
              y = 4;
            };
          };
        };
      };
    };

    test.stubs.autorandr = { };

    nmt.script = ''
      config=home-files/.config/autorandr/default/config

      assertFileExists $config
      assertFileContent $config \
          ${
            pkgs.writeText "scale-expected.conf" ''
              output DP1
              scale 2x4''
          }
    '';
  };
}
