{
  config,
  lib,
  options,
  ...
}:

{
  imports = [
    {
      services.xsuspender = {
        settings = {
          Default.resume_every = lib.mkForce 45;
          Chromium.resume_for = 8;
        };
      };
    }
  ];

  services.xsuspender = {
    enable = true;
    defaults = {
      suspendDelay = 7;
      resumeEvery = 30;
      resumeFor = 4;
      sendSignals = false;
      onlyOnBattery = true;
      autoSuspendOnBattery = false;
      downclockOnBattery = 2;
      execSuspend = null;
    };
    rules.Browser = {
      matchWmClassContains = "browser";
      resumeFor = config.services.xsuspender.defaults.suspendDelay + 1;
      execResume = config.services.xsuspender.rules.Browser.matchWmClassContains;
    };
    rules.Custom.matchWmClassContains = "overridden";
    rules.Chromium = {
      matchWmClassContains = "chromium-browser";
      matchWmNameContains = "Google Chrome";
      suspendSubtreePattern = "chromium";
      execSuspend = ''echo "suspend $PID"'';
      execResume = ''echo "resume $PID"'';
    };
    settings = {
      Default.suspend_delay = lib.mkForce 9;
      Chromium.resume_every = 70;
      Chromium.suspend_delay = 11;
      Modern.match_wm_class_contains = "modern";
      Custom = lib.mkForce { match_wm_class_contains = "custom"; };
    };
  };

  assertions = [
    {
      assertion = config.services.xsuspender.defaults.suspendDelay == 9;
      message = "The old defaults alias must read the canonical forced value.";
    }
    {
      assertion = config.services.xsuspender.rules.Browser.matchWmClassContains == "browser";
      message = "The old rules alias must keep camelCase fields readable.";
    }
  ];

  test.asserts.warnings.expected = [
    "The option `services.xsuspender.rules' defined in ${lib.showFiles options.services.xsuspender.rules.files} has been renamed to `services.xsuspender.settings'."
    "The option `services.xsuspender.defaults' defined in ${lib.showFiles options.services.xsuspender.defaults.files} has been renamed to `services.xsuspender.settings.Default'."
  ];

  nmt.script = ''
    assertFileContent home-files/.config/xsuspender.conf ${./basic-configuration.conf}
  '';
}
