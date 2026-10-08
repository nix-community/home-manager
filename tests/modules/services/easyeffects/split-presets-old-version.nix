{ config, ... }:

{
  services.easyeffects = {
    enable = true;
    package = config.lib.test.mkStubPackage { version = "8.0.8"; };
    preset.input = "home";
  };

  test.asserts.assertions.expected = [
    "Structured `services.easyeffects.preset` requires EasyEffects 8.0.9 or later."
  ];
}
