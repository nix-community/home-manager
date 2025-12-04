{
  # Test that when home.uid is null, checkUid should not be called in the activation script
  home.uid = null;

  nmt.script = ''
    assertFileNotRegex activate "checkUid [0-9]+"
  '';
}
