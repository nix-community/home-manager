{
  config,
  lib,
  options,
  ...
}:

{
  services.grobi = {
    enable = true;
    executeAfter = lib.mkDefault [ "legacy-default" ];
    rules = lib.mkForce [ { name = "Legacy forced"; } ];
    settings = {
      execute_after = [ "canonical" ];
      rules = [ { name = "Canonical loses"; } ];
    };
  };

  assertions = [
    {
      assertion = config.services.grobi.executeAfter == [ "canonical" ];
      message = "An ordinary canonical command must override a legacy default.";
    }
    {
      assertion = config.services.grobi.rules == [ { name = "Legacy forced"; } ];
      message = "A forced legacy rule must retain its definition priority.";
    }
  ];

  test.asserts.warnings.expected = [
    "The option `services.grobi.rules' defined in ${lib.showFiles options.services.grobi.rules.files} has been renamed to `services.grobi.settings.rules'."
    "The option `services.grobi.executeAfter' defined in ${lib.showFiles options.services.grobi.executeAfter.files} has been renamed to `services.grobi.settings.execute_after'."
  ];

  nmt.script = ''
    assertFileContent home-files/.config/grobi.conf ${./priority-settings.json}
  '';
}
