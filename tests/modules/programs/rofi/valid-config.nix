{
  config,
  lib,
  options,
  ...
}:
{
  programs.rofi = {
    enable = true;
    font = lib.mkForce "modeled";
    terminal = lib.mkMerge [
      (lib.mkDefault "/default")
      "/some/path"
    ];
    cycle = false;
    location = lib.mkDefault "bottom-left";
    xoffset = lib.mkDefault 12;
    yoffset = 9;
    settings = {
      yoffset = 3;
      filebrowser = lib.mkDefault { sorting-method = "type"; };
      combi-modes = lib.mkDefault [ "drun" ];
    };
    modes = lib.mkMerge [
      (lib.mkBefore [ "drun" ])
      (lib.mkAfter [ "ssh" ])
      [
        "emoji"
        {
          name = "foo";
          path = lib.mkDefault "bar";
        }
      ]
    ];
    extraConfig = lib.mkDefault {
      terminal = lib.mkIf false "/ignored";
      font = lib.mkOptionDefault "Droid Sans Mono 14";
      xoffset = lib.mkOptionDefault 22;
      combi-modes = lib.mkBefore [ "window" ];
      kb-primary-paste = "Control+V,Shift+Insert";
      kb-secondary-paste = "Control+v,Insert";
      modi = [
        "run"
        "drun"
        "window"
        "ssh"
      ];
      drun = {
        display-name = "";
      };
      "run,drun" = {
        display-name = "open:";
      };
      filebrowser = {
        directory = "$HOME";
        sorting-method = lib.mkDefault "name";
        directories-first = true;
      };
    };
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
          "yoffset"
          "xoffset"
          "cycle"
          "terminal"
          "font"
        ]
    ++ [
      "The option `programs.rofi.extraConfig' defined in ${lib.showFiles options.programs.rofi.extraConfig.files} has been renamed to `programs.rofi.settings'."
    ];

  test.asserts.assertions.expected = [ ];

  assertions = [
    {
      assertion =
        config.programs.rofi.extraConfig == config.programs.rofi.settings
        && config.programs.rofi.font == config.programs.rofi.settings.font
        && config.programs.rofi.xoffset == 22;
      message = "Unchanged aliases must read the merged settings.";
    }
  ];

  nmt.script = ''
    assertFileContent \
      home-files/.config/rofi/config.rasi \
      ${./valid-config-expected.rasi}
  '';
}
