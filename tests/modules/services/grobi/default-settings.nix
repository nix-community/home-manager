{ config, ... }:

{
  services.grobi.enable = true;

  assertions = [
    {
      assertion = config.services.grobi.executeAfter == [ ];
      message = "The executeAfter alias must retain its empty default.";
    }
    {
      assertion = config.services.grobi.rules == [ ];
      message = "The rules alias must retain its empty default.";
    }
  ];

  test.asserts.warnings.expected = [ ];

  nmt.script = ''
    assertFileContent home-files/.config/grobi.conf ${./default-settings.json}
    assertFileContent home-files/.config/systemd/user/grobi.service ${./grobi.service}
  '';
}
