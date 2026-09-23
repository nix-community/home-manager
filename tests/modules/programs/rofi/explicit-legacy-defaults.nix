{ lib, options, ... }:
{
  programs.rofi = {
    enable = true;
    location = "center";
    xoffset = 0;
    yoffset = 0;
  };

  test.asserts.warnings.expected = [
    "The option `programs.rofi.location' defined in ${lib.showFiles options.programs.rofi.location.files} has been changed to `programs.rofi.settings.location' that has a different type. Please read `programs.rofi.settings.location' documentation and update your configuration accordingly."
  ]
  ++
    map
      (
        name:
        "The option `programs.rofi.${name}' defined in ${
          lib.showFiles options.programs.rofi.${name}.files
        } has been renamed to `programs.rofi.settings.${name}'."
      )
      [
        "yoffset"
        "xoffset"
      ];

  nmt.script = ''
    assertFileContent home-files/.config/rofi/config.rasi ${builtins.toFile "expected.rasi" ''
      configuration {
      location: 0;
      xoffset: 0;
      yoffset: 0;
      }
    ''}
  '';
}
