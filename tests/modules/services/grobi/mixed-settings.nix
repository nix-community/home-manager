{
  config,
  lib,
  options,
  ...
}:
let
  executeAfter = [
    "legacy-before"
    "canonical-middle"
    "legacy-after"
  ];
  rules = [
    { name = "Legacy before"; }
    { name = "Canonical middle"; }
    { name = "Legacy after"; }
  ];
in
{
  imports = [
    {
      services.grobi = {
        executeAfter = lib.mkBefore [ "legacy-before" ];
        rules = lib.mkBefore [ { name = "Legacy before"; } ];
      };
    }
    {
      services.grobi = {
        executeAfter = lib.mkAfter [ "legacy-after" ];
        rules = lib.mkAfter [ { name = "Legacy after"; } ];
      };
    }
  ];

  services.grobi = {
    enable = true;
    settings = {
      execute_after = [ "canonical-middle" ];
      on_failure = [ "recover" ];
      rules = [ { name = "Canonical middle"; } ];
    };
  };

  assertions = [
    {
      assertion = config.services.grobi.executeAfter == executeAfter;
      message = "The executeAfter alias must read mixed command definitions.";
    }
    {
      assertion = config.services.grobi.rules == rules;
      message = "The rules alias must read mixed rule definitions.";
    }
  ];

  test.asserts.warnings.expected = [
    "The option `services.grobi.rules' defined in ${lib.showFiles options.services.grobi.rules.files} has been renamed to `services.grobi.settings.rules'."
    "The option `services.grobi.executeAfter' defined in ${lib.showFiles options.services.grobi.executeAfter.files} has been renamed to `services.grobi.settings.execute_after'."
  ];

  nmt.script = ''
    assertFileContent home-files/.config/grobi.conf ${./mixed-settings.json}
  '';
}
