{
  home.file.testfile.text = "not special";
  specialisation.test.configuration = {
    home.file.testfile.text = "very special";
  };

  nmt.script = ''
    assertFileExists home-files/testfile
    assertFileContains home-files/testfile "not special"

    assertFileExists specialisation/test/home-files/testfile
    assertFileContains specialisation/test/home-files/testfile "not special"
    assertFileContains specialisation/test/home-files/testfile "very special"
  '';
}
