{ config, lib, ... }:

with lib;

{
  config = {
    xresources = {
      properties = {
        "Test*string" = "test-string";
        "Test*boolean1" = true;
        "Test*boolean2" = false;
        "Test*int" = 10;
        "Test*list" = [ "list-str" true false 10 ];
      };
    };

    nmt.script = ''
      assertFileExists home-files/.Xresources
      assertFileContent home-files/.Xresources ${./xresources-expected.conf}
    '';
  };
}
