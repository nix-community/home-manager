{ lib, options, ... }:

{
  services.xsuspender = {
    enable = true;
    defaults.suspendDelay = 3;
    rules.Unused.matchWmClassContains = "unused";
    settings = lib.mkForce {
      Default = {
        suspend_delay = 12;
      };
      Custom = {
        match_wm_class_contains = "custom";
      };
    };
  };

  test.asserts.warnings.expected = [
    "The option `services.xsuspender.rules' defined in ${lib.showFiles options.services.xsuspender.rules.files} has been renamed to `services.xsuspender.settings'."
    "The option `services.xsuspender.defaults' defined in ${lib.showFiles options.services.xsuspender.defaults.files} has been renamed to `services.xsuspender.settings.Default'."
  ];

  nmt.script = ''
    assertFileContent home-files/.config/xsuspender.conf ${./whole-tree-force.conf}
  '';
}
