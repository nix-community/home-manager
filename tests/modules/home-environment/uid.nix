{
  home.uid = 1000;

  nmt.script = ''
    assertFileContains activate 'checkStringEq UID "$(id -u)" 1000'
  '';
}
