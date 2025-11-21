{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "John Doe";
        email = "user@example.org";
      };
    };

    signing = {
      signer = "path-to-ssh";
      format = "ssh";
      key = "ssh-ed25519 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
      signByDefault = true;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    assertFileContent home-files/.config/git/config ${./git-with-signing-key-id-expected.conf}
  '';
}
