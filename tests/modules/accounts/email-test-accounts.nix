{ ... }:

{
  accounts.email = {
    maildirBasePath = "Mail";

    accounts = {
      "hm@example.com" = {
        address = "hm@example.com";
        userName = "home.manager";
        realName = "H. M. Test";
        passwordCommand = "password-command";
        imap.host = "imap.example.com";
        smtp.host = "smtp.example.com";
      };

      hm-account = {
        address = "hm@example.org";
        userName = "home.manager.jr";
        realName = "H. M. Test Jr.";
        passwordCommand = "password-command 2";
        imap.host = "imap.example.org";
        smtp.host = "smtp.example.org";
        smtp.tls.useStartTls = true;
      };
    };
  };
}
