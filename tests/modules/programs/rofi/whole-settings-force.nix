{ lib, options, ... }:
{
  programs.rofi = {
    enable = true;
    font = lib.mkForce "legacy";
    extraConfig.cycle = false;
    extraConfig.location = 9;
    settings = lib.mkForce { font = "canonical"; };
  };

  test.asserts.warnings.expected = [
    "The option `programs.rofi.font' defined in ${lib.showFiles options.programs.rofi.font.files} has been renamed to `programs.rofi.settings.font'."
    "The option `programs.rofi.extraConfig' defined in ${lib.showFiles options.programs.rofi.extraConfig.files} has been renamed to `programs.rofi.settings'."
  ];

  nmt.script = ''
    assertFileContent home-files/.config/rofi/config.rasi ${./whole-settings-force.rasi}
  '';
}
