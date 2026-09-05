{
  lib,
  options,
  ...
}:

{
  services.gromit-mpx = {
    enable = true;
    opacity = 0.5;
  };

  test.asserts.warnings.expected = [
    "The option `services.gromit-mpx.opacity' defined in ${lib.showFiles options.services.gromit-mpx.opacity.files} has been renamed to `services.gromit-mpx.iniSettings.Drawing.Opacity'."
  ];

  nmt.script = import ./nmt-script.nix {
    goldenFile = ./default-configuration.cfg;
    opacity = "0.500000";
  };
}
