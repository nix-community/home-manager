{
  home.quietLogin = true;

  nmt.script = ''
    assertFileExists home-files/.hushlogin
    assertFileContent home-files/.hushlogin ${builtins.toFile "hushlogin-expected" ""}
  '';
}
