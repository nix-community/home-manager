{ config, pkgs, ... }: {
  config = {
    services.kanshi = {
      enable = true;
      package = config.lib.test.mkStubPackage { };
      profiles = {
        nomad = {
          outputs = [{
            criteria = "eDP-1";
            status = "enable";
          }];
        };
        desktop = {
          exec = [ ''echo "1 two 3"'' ''echo "4 five 6"'' ];
          outputs = [
            {
              criteria = "eDP-1";
              status = "disable";
            }
            {
              criteria = "Iiyama North America PLE2483H-DP";
              status = "enable";
              position = "0,0";
            }
            {
              criteria = "Iiyama North America PLE2483H-DP 1158765348486";
              status = "enable";
              position = "1920,0";
              scale = 2.1;
              mode = "1920x1080";
              transform = "flipped-270";
            }
          ];
        };
        backwardsCompat = {
          outputs = [{
            criteria = "LVDS-1";
            status = "enable";
          }];
          exec = ''echo "7 eight 9"'';
        };
      };
      extraConfig = ''
        profile test {
          output "*" enable
        }
      '';
    };

    test.asserts.warnings.expected = [
      "kanshi.profiles option is deprecated. Use kanshi.settings instead."
      "kanshi.extraConfig option is deprecated. Use kanshi.settings instead."
    ];

    nmt.script = ''
      serviceFile=home-files/.config/systemd/user/kanshi.service
      assertFileExists $serviceFile

      assertFileExists home-files/.config/kanshi/config
      assertFileContent home-files/.config/kanshi/config \
                ${./basic-configuration.conf}
    '';
  };
}
