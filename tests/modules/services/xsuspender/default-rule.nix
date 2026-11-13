{ lib, options, ... }:
{
  services.xsuspender = {
    enable = true;
    defaults = { };
    rules.Default.suspendDelay = 11;
  };

  test.asserts.warnings.expected = [
    "The option `services.xsuspender.rules' defined in ${lib.showFiles options.services.xsuspender.rules.files} has been renamed to `services.xsuspender.settings'."
    "The option `services.xsuspender.defaults' defined in ${lib.showFiles options.services.xsuspender.defaults.files} has been renamed to `services.xsuspender.settings.Default'."
  ];

  nmt.script = ''
    assertFileContent home-files/.config/xsuspender.conf ${./default-rule.conf}
  '';
}
