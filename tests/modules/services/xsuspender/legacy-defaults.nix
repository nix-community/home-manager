{ lib, options, ... }:
{
  services.xsuspender = {
    enable = true;
    defaults = { };
  };

  test.asserts.warnings.expected = [
    "The option `services.xsuspender.defaults' defined in ${lib.showFiles options.services.xsuspender.defaults.files} has been renamed to `services.xsuspender.settings.Default'."
  ];

  nmt.script = ''
    assertFileContent home-files/.config/xsuspender.conf ${./legacy-defaults.conf}
  '';
}
