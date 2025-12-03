{
  accounts.email.accounts."protocol-test" = {
    primary = true;
    address = "test@example.com";
    userName = "default-user";
    realName = "Test User";
    passwordCommand = "pass test";
    maildir.path = "protocol-test";

    imap = {
      host = "imap.example.com";
      userName = "imap-specific-user";
    };

    smtp = {
      host = "smtp.example.com";
      userName = "smtp-specific-user";
    };

    mbsync.enable = true;
  };

  programs.mbsync.enable = true;

  nmt.script = ''
    assertFileExists home-files/.config/isyncrc
    assertFileContent home-files/.config/isyncrc ${./mbsync-protocol-usernames-expected.conf}
  '';
}
