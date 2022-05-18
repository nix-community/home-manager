{ config, lib, pkgs, ... }:

with lib;

{
  home.file.testfile.text = "not special";
  specialization.test.configuration = {
    home.file.testfile.text = "very special";
  };

  nmt.script = ''
    assertFileExists home-files/testfile
    assertFileContains home-files/testfile "not special"

    assertFileExists specialization/test/home-files/testfile
    assertFileContains specialization/test/home-files/testfile "not special"
  '';
}
