{ lib, options, ... }:
{
  programs.rofi = {
    enable = true;
    font = lib.mkForce "modeled";
    cycle = false;
    terminal = "/some/terminal";
    location = "bottom";
    modes = [ "legacy" ];
    extraConfig = lib.mkForce {
      yoffset = lib.mkIf false 42;
      font = "forced-overlay";
      location = lib.mkOptionDefault 4;
      modes = [ "native" ];
      terminal = lib.mkIf true (lib.mkDefault "/conditional");
    };
    settings.terminal = "/canonical";
  };

  test.asserts.warnings.expected =
    map
      (
        name:
        "The option `programs.rofi.${name}' defined in ${
          lib.showFiles options.programs.rofi.${name}.files
        } has been changed to `programs.rofi.settings' that has a different type. Please read `programs.rofi.settings' documentation and update your configuration accordingly."
      )
      [
        "modes"
        "location"
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
          "cycle"
          "terminal"
          "font"
        ]
    ++ [
      "The option `programs.rofi.extraConfig' defined in ${lib.showFiles options.programs.rofi.extraConfig.files} has been renamed to `programs.rofi.settings'."
    ];

  nmt.script = ''
    assertFileContent home-files/.config/rofi/config.rasi ${./whole-extra-config-force.rasi}
  '';
}
