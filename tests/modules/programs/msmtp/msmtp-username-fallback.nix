{
  accounts.email.accounts."fallback-test" = {
    primary = true;
    address = "test@example.com";
    userName = "default-user";
    realName = "Test User";
    passwordCommand = "pass test";

    imap.host = "imap.example.com";
    smtp.host = "smtp.example.com";

    msmtp.enable = true;
  };

  programs.msmtp.enable = true;

  nmt.script = ''
    assertFileExists home-files/.config/msmtp/config
    assertFileContent home-files/.config/msmtp/config ${./msmtp-username-fallback-expected.conf}
  '';
}
