{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "John Doe";
        email = "user@example.org";
      };
    };
  };

  home.stateVersion = "24.05";

  test.asserts.evalWarnings.expected = [ ];

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    assertFileContent home-files/.config/git/config ${./git-without-signing-legacy.conf}
  '';
}
