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

  home.stateVersion = "25.05";

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    assertFileContent home-files/.config/git/config ${./git-without-signing.conf}
  '';
}
