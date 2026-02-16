{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "John Doe";
        email = "user@example.org";
      };
    };

    lfs = {
      enable = true;
      skipSmudge = true;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    assertFileContent home-files/.config/git/config ${./git-with-lfs-expected.conf}
  '';
}
