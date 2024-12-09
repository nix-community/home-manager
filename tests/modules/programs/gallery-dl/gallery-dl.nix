{ config, ... }:

{
  programs.gallery-dl = {
    enable = true;

    package = config.lib.test.mkStubPackage { };

    settings = {
      cache.file = "~/gallery-dl/cache.sqlite3";
      extractor.base-directory = "~/gallery-dl/";
    };
  };

  test.stubs.gallery-dl = { };

  nmt.script = ''
    assertFileContent home-files/.config/gallery-dl/config.json \
    ${builtins.toFile "gallery-dl-expected-settings.json" ''
      {
        "cache": {
          "file": "~/gallery-dl/cache.sqlite3"
        },
        "extractor": {
          "base-directory": "~/gallery-dl/"
        }
      }
    ''}
  '';
}
