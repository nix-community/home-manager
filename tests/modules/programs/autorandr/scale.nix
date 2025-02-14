{
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

  nmt.script = ''
    config=home-files/.config/autorandr/default/config

    assertFileExists $config
    assertFileContent $config \
        ${
          builtins.toFile "scale-expected.conf" ''
            output DP1
            scale 2x4''
        }
  '';
}
