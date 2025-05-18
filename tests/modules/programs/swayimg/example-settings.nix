{ config, ... }:

{
  programs.swayimg = {
    enable = true;
    package = config.lib.test.mkStubPackage { };

    settings = {
      viewer = {
        window = "#10000010";
        scale = "fill";
      };
      "info.viewer" = {
        top_left = "+name,+format";
      };
      "keys.viewer" = {
        "Shift+r" = "rand_file";
      };
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/swayimg/config \
      ${./example-settings-expected.ini}
  '';
}
