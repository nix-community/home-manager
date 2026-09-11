{
  lib,
  options,
  ...
}:

{
  imports = [
    {
      services.xsuspender.rules.Chromium = { config, lib, ... }: {
        resumeFor = config.suspendDelay + 3;
        resumeEvery = lib.mkDefault 30;
        downclockOnBattery = lib.mkDefault 2;
        suspendSubtreePattern = lib.mkDefault "chromium-old";
      };
    }
  ];

  services.xsuspender = {
    enable = true;
    rules.Empty = { };
    rules.Default = lib.mkIf false { suspendDelay = 100; };
    rules.Disabled = lib.mkIf false { matchWmClassContains = "disabled"; };
    rules.Chromium = {
      matchWmClassContains = "chromium-browser";
      execSuspend = ''echo "suspend $PID"'';
      resumeEvery = 70;
    };
  };

  test.asserts.warnings.expected = [
    "The option `services.xsuspender.rules' defined in ${lib.showFiles options.services.xsuspender.rules.files} has been renamed to `services.xsuspender.settings'."
  ];

  nmt.script = ''
    assertFileContent home-files/.config/xsuspender.conf ${./rules-only.conf}
  '';
}
