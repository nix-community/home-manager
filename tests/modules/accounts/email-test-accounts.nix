{
  accounts.email = {
    maildirBasePath = "Mail";

    accounts = {
      "hm@example.com" = {
        primary = true;
        address = "hm@example.com";
        realName = "H. M. Test";
        auth.userName = "home.manager";
        auth.passwordCommand = "password-command";
        imap.host = "imap.example.com";
        smtp.host = "smtp.example.com";
      };

      hm-account = {
        address = "hm@example.org";
        realName = "H. M. Test Jr.";
        auth.userName = "home.manager.jr";
        auth.passwordCommand = "password-command 2";
        imap.host = "imap.example.org";
        smtp.host = "smtp.example.org";
        smtp.tls.useStartTls = true;
      };
    };
  };
}
