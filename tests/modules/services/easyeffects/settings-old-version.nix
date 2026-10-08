{ config, ... }:

{
  services.easyeffects = {
    enable = true;
    package = config.lib.test.mkStubPackage { version = "7.2.0"; };
    settings.StreamOutputs.useDefaultOutputDevice = true;
  };

  test.asserts.assertions.expected = [
    "`services.easyeffects.settings` requires EasyEffects 8.0.0 or later."
  ];
}
