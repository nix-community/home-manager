{ config, lib, ... }:

with lib;

{
  config = {
    home.file."source with spaces!".source = ./. + "/source with spaces!";

    nmt.script = ''
      assertFileExists 'home-files/source with spaces!';
      assertFileContent 'home-files/source with spaces!' \
        ${
          builtins.path {
            path = ./. + "/source with spaces!";
            name = "source-with-spaces-expected";
          }
        }
    '';
  };
}
