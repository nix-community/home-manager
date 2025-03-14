{
  programs.bash = {
    enable = true;
    enableCompletion = false;

    logoutExtra = ''
      clear-console
    '';
  };

  nmt.script = ''
    assertFileExists home-files/.bash_logout
    assertFileContent \
      home-files/.bash_logout \
      ${
        builtins.toFile "logout-expected" ''
          clear-console
        ''
      }
  '';
}
