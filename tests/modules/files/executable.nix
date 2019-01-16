{ config, lib, ... }:

with lib;

{
  config = {
    home.file."executable" = {
      text = "";
      executable = true;
    };

    nmt.script = ''
      assertFileExists home-files/executable
      assertFileIsExecutable home-files/executable;
    '';
  };
}
