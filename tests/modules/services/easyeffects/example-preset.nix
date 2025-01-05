{ ... }:

{
  services.easyeffects = {
    enable = true;
    extraPresets = {
      example-preset = {
        input = {
          blocklist = [

          ];
          "plugins_order" = [ "rnnoise#0" ];
          "rnnoise#0" = {
            bypass = false;
            "enable-vad" = false;
            "input-gain" = 0.0;
            "model-path" = "";
            "output-gain" = 0.0;
            release = 20.0;
            "vad-thres" = 50.0;
            wet = 0.0;
          };
        };
      };
    };
  };

  test.stubs.easyeffects = { };

  nmt.script = ''
    assertFileContent \
      home-files/.config/easyeffects/input/example-preset.json "${
        ./example-preset.json
      }"
  '';
}
