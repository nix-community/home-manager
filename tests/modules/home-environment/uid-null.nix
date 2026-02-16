{
  # home.uid defaults to null, so checkUid should not be called in the activation script

  nmt.script = ''
    assertFileNotRegex activate "checkStringEq UID"
  '';
}
