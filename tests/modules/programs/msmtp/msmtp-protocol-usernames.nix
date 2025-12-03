{
  accounts.email.accounts."protocol-test" = {
    primary = true;
    address = "test@example.com";
    userName = "default-user";
    realName = "Test User";
    passwordCommand = "pass test";

    imap = {
      host = "imap.example.com";
      userName = "imap-specific-user";
    };

    smtp = {
      host = "smtp.example.com";
      userName = "smtp-specific-user";
    };

    msmtp.enable = true;
  };

  programs.msmtp.enable = true;

  nmt.script = ''
    assertFileExists home-files/.config/msmtp/config
    assertFileContent home-files/.config/msmtp/config ${./msmtp-protocol-usernames-expected.conf}
  '';
}
