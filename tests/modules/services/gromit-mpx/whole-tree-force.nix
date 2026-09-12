{
  config,
  lib,
  options,
  ...
}:

{
  services.gromit-mpx = {
    enable = true;
    opacity = 0.25;
    iniSettings = lib.mkForce {
      Drawing.Opacity = 0.5;
      General.ShowIntroOnStartup = true;
    };
    hotKey = 42;
    undoKey = null;
  };

  assertions = [
    {
      assertion = config.services.gromit-mpx.opacity == 0.5;
      message = "Legacy opacity must read back the forced canonical value.";
    }
  ];

  test.asserts.warnings.expected = [
    "The option `services.gromit-mpx.opacity' defined in ${lib.showFiles options.services.gromit-mpx.opacity.files} has been renamed to `services.gromit-mpx.iniSettings.Drawing.Opacity'."
  ];

  nmt.script = ''
    assertFileContent home-files/.config/gromit-mpx.ini ${builtins.toFile "expected.ini" ''
      [Drawing]
      Opacity=0.500000

      [General]
      ShowIntroOnStartup=true
    ''}
    assertFileContent home-files/.config/gromit-mpx.cfg ${./default-configuration.cfg}
    assertFileRegex home-files/.config/systemd/user/gromit-mpx.service 'ExecStart=.*/bin/gromit-mpx --keycode 42 --undo-key none$'
  '';
}
