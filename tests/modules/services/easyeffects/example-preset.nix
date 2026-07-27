{ options, ... }:

let
  presetType =
    options.services.easyeffects.extraPresets.type.nestedTypes.elemType.nestedTypes.elemType;
in
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
        output = {
          blocklist = [ ];
          "plugins_order" = [ "limiter#0" ];
          "limiter#0" = {
            bypass = false;
            threshold = -1.0;
          };
        };
      };
    };
  };

  test.stubs.easyeffects = { };

  nmt.script =
    assert
      !(presetType.check {
        input = { };
        outpt = { };
      });
    assert !(presetType.check { });
    ''
      inputPreset=home-files/.local/share/easyeffects/input/example-preset.json
      outputPreset=home-files/.local/share/easyeffects/output/example-preset.json

      assertFileContent "$inputPreset" "${./example-preset.json}"
      assertFileContent "$outputPreset" "${./example-preset-output.json}"
    '';
}
