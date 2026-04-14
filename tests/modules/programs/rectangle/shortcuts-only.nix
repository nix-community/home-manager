{ config, ... }:

{
  programs.rectangle = {
    enable = true;
    package = config.lib.test.mkStubPackage { name = "rectangle"; };

    shortcuts = {
      leftHalf = {
        keyCode = 123;
        modifierFlags = "ctrl+option+command";
      };
      rightHalf = {
        keyCode = 124;
        modifierFlags = "ctrl+option+command";
      };
      maximize = {
        keyCode = 46;
        modifierFlags = "shift+command";
      };
    };
  };

  nmt.script = ''
    configFile="home-files/Library/Application Support/Rectangle/RectangleConfig.json"
    assertFileExists "$configFile"
    assertFileContent "$configFile" ${./shortcuts-only-expected.json}
  '';
}
