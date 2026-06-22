{ config, ... }:
{
  programs.google-chrome = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "google-chrome";
    };
    extensions = [
      {
        id = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
      }
    ];
  };

  programs.chromium = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "google-chrome-dev";
    };
    extensions = [
      {
        id = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb";
      }
    ];
  };

  test.asserts.assertions.expected = [
    "Cannot set `extensions` for `google-chrome-dev` on Linux. Google Chrome only loads external extensions from system-managed directories, which Home Manager does not manage."
    "Cannot set `extensions` for `google-chrome` on Linux. Google Chrome only loads external extensions from system-managed directories, which Home Manager does not manage."
  ];
}
