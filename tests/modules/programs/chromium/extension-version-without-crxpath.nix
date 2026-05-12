{ config, ... }:
{
  programs.chromium = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "chromium";
    };
    extensions = [
      {
        id = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
        version = "1.0";
      }
    ];
  };

  test.asserts.assertions.expected = [
    "Cannot set `version` without `crxPath`, or `crxPath` without `version`, for `chromium`."
  ];
}
