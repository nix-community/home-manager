{ config, ... }:
{
  programs.vicinae = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "vicinae";
      version = "0.16.11";
    };
    enableFirefoxIntegration = false;
  };
  test.asserts.assertions.expected = [
    "programs.vicinae requires Vicinae 0.17.0 or later. Upgrade programs.vicinae.package to a supported version."
  ];
}
