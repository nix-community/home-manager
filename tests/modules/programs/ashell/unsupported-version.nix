{ config, ... }:
{
  programs.ashell = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "ashell";
      version = "0.4.1";
    };
  };

  test.asserts.assertions.expected = [
    "programs.ashell requires ashell 0.5.0 or later. Upgrade programs.ashell.package to a supported version."
  ];
}
