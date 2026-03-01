{
  accounts.email.accounts."fallback-test" = {
    primary = true;
    address = "test@example.com";
    userName = "default-user";
    realName = "Test User";
    passwordCommand = "pass test";
    maildir.path = "fallback-test";

    imap.host = "imap.example.com";
    smtp.host = "smtp.example.com";

    mbsync.enable = true;
  };

  programs.mbsync.enable = true;

  nmt.script = ''
    assertFileExists home-files/.config/isyncrc
    assertFileContent home-files/.config/isyncrc ${./mbsync-username-fallback-expected.conf}
  '';
}
