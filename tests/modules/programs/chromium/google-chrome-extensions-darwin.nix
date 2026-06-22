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
        updateUrl = "https://example.com/update.xml";
      }
    ];
  };

  programs.google-chrome-beta = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "google-chrome-beta";
    };
    extensions = [
      {
        crxPath = ./google-chrome-extensions-darwin.nix;
        id = "cccccccccccccccccccccccccccccccc";
        version = "1.0";
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
        updateUrl = "https://example.com/update.xml";
      }
    ];
  };

  test.asserts.assertions.expected = [
    "Cannot set `crxPath`, `version`, or a custom `updateUrl` for `google-chrome-dev` on Darwin. Google Chrome only supports Chrome Web Store external extensions there."
    "Cannot set `crxPath`, `version`, or a custom `updateUrl` for `google-chrome` on Darwin. Google Chrome only supports Chrome Web Store external extensions there."
    "Cannot set `crxPath`, `version`, or a custom `updateUrl` for `google-chrome-beta` on Darwin. Google Chrome only supports Chrome Web Store external extensions there."
  ];
}
