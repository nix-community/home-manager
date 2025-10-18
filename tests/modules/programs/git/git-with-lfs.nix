{
  programs.git = {
    enable = true;
    userName = "John Doe";
    userEmail = "user@example.org";

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
