{ config, ... }:

{
  programs.rectangle = {
    enable = true;
    package = config.lib.test.mkStubPackage { name = "rectangle"; };

    defaults = {
      launchOnLogin = {
        bool = true;
      };
      gapSize = {
        float = 8.0;
      };
      windowSnapping = {
        int = 1;
      };
    };
  };

  nmt.script = ''
    configFile="home-files/Library/Application Support/Rectangle/RectangleConfig.json"
    assertFileExists "$configFile"
    assertFileContent "$configFile" ${./defaults-only-expected.json}
  '';
}
