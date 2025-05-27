{
  programs.git = {
    enable = true;
    signing = {
      signer = "path-to-gpg";
      format = "openpgp";
      key = "00112233445566778899AABBCCDDEEFF";
      signByDefault = true;
    };
    userEmail = "user@example.org";
    userName = "John Doe";

    patdiff.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    assertFileContent home-files/.config/git/config ${./git-patdiff-expected.conf}
  '';
}
