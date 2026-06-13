{
  test.stubs.imapgoose = { };

  programs.imapgoose = {
    enable = true;
    extraConfig = "# Global extra config";
  };

  accounts.email = {
    maildirBasePath = "mail";
    accounts = {
      "example" = {
        primary = true;
        address = "user@example.com";
        userName = "user@example.com";
        passwordCommand = "hiq -dF password proto=imaps host=imap.example.com";
        maildir.path = "example";
        imap = {
          host = "imap.example.com";
          port = 993;
          tls.enable = true;
        };

        imapgoose = {
          enable = true;
          maxConnections = 3;
          postSyncCmd = "notmuch new";
        };
      };

      "work" = {
        address = "work@work.com";
        userName = "work@work.com";
        passwordCommand = "pass show email/work";
        maildir.path = "work";
        imap = {
          host = "imap.work.com";
          port = 993;
        };

        imapgoose = {
          enable = true;
          maxConnections = 5;
          extraConfig = {
            debug = true;
            tags = [
              "work"
              "priority"
            ];
          };
        };
      };

      # An account with imapgoose disabled to double-check filtering
      "ignored" = {
        address = "ignored@domain.com";
        maildir.path = "ignored";
        imapgoose.enable = false;
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/imapgoose/config.scfg
    assertFileContent home-files/.config/imapgoose/config.scfg ${./imapgoose-expected.conf}
  '';
}
