{
  home.uid = 1000;

  nmt.script = ''
    assertFileContains activate "checkUid 1000"
  '';
}
