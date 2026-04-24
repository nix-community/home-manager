{ config, ... }:

{
  programs.rectangle = {
    enable = true;
    package = config.lib.test.mkStubPackage { name = "rectangle"; };

    defaults = {
      launchOnLogin = true;
      footprintAlpha = 0.3;
    };

    shortcuts = {
      leftHalf = {
        keyCode = 123;
        modifierFlags = "ctrl+option+command";
      };
      center = {
        keyCode = 8;
        modifierFlags = "ctrl+option+command";
      };
    };
  };

  nmt.script = ''
    configFile="home-files/Library/Preferences/com.knollsoft.Rectangle.plist"
    assertFileExists "$configFile"
    assertFileContent "$configFile" ${./defaults-and-shortcuts-expected.plist}
  '';
}
