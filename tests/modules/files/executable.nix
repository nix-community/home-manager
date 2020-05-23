{ config, lib, ... }:

with lib;

{
  config = {
    home.file."executable" = {
      text = "";
      executable = true;
    };

    nmt.script = ''
      assertFileExists $home_files/executable
      assertFileIsExecutable $home_files/executable;
    '';
  };
}
