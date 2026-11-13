{ config, ... }:
{
  imports = [ ../../accounts/email-test-accounts.nix ];

  config = {
    accounts.email.accounts = {
      "hm@example.com" = {
        getmail = {
          enable = true;
          mailboxes = [
            "INBOX"
            "Sent"
            "Work"
          ];
          destinationCommand = "/bin/maildrop";
          delete = false;
        };
        imap.port = 993;
      };
    };

    assertions = [
      {
        assertion = !config.accounts.email.accounts.hm-account.getmail.delete;
        message = "Disabled getmail accounts retain the legacy delete default.";
      }
      {
        assertion = config.accounts.email.accounts.hm-account.getmail.readAll;
        message = "Disabled getmail accounts retain the legacy readAll default.";
      }
    ];

    nmt.script = ''
      assertPathNotExists home-files/.getmail/getmaildisabled-account
      assertPathNotExists home-files/.getmail/getmailhm-account
      assertFileExists home-files/.getmail/getmailrc
      assertFileContent home-files/.getmail/getmailrc ${./getmail-expected.conf}
    '';
  };
}
