{ config, ... }:

{
  programs.rectangle = {
    enable = true;
    package = config.lib.test.mkStubPackage { name = "rectangle"; };

    defaults = {
      launchOnLogin = true;
      gapSize = 8.0;
      windowSnapping = 1;
    };
  };

  nmt.script = ''
    configFile="home-files/Library/Preferences/com.knollsoft.Rectangle.plist"
    assertFileExists "$configFile"
    assertFileContent "$configFile" ${./defaults-only-expected.plist}
  '';
}
