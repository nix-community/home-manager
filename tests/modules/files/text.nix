{ config, lib, ... }:

with lib;

{
  config = {
    home.file."using-text".text = ''
      This is the
      expected text.
    '';

    nmt.script = ''
      assertFileExists $home_files/using-text
      assertFileIsNotExecutable $home_files/using-text
      assertFileContent $home_files/using-text ${./text-expected.txt}
    '';
  };
}
