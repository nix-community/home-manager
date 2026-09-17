{ lib, ... }:
{
  imports = [
    ../../accounts/email-test-accounts.nix
    {
      accounts.email.accounts."hm@example.com".getmail.settings = {
        retriever.imap_search = "UNSEEN";
        options.verbose = lib.mkDefault 0;
        "filter-1".type = "Filter_external";
      };
    }
    {
      accounts.email.accounts."hm@example.com".getmail.settings = {
        options.verbose = 2;
        "filter-1".path = "/bin/true";
      };
    }
  ];

  accounts.email.accounts = {
    "hm@example.com" = {
      passwordCommand = lib.mkForce [
        "password-command"
        ''argument"with-quotes''
      ];
      getmail = {
        enable = true;
        mailboxes = [ ''INBOX."quoted"'' ];
        destinationCommand = "/bin/maildrop";
        delete = true;
        readAll = lib.mkDefault false;
        settings = {
          options.delete = lib.mkForce false;
          destination.arguments = "('--message-from-stdin',)";
        };
      };
    };
    forced-account = {
      address = "forced@example.org";
      realName = "Forced Account";
      getmail = {
        enable = true;
        settings = lib.mkForce {
          retriever = {
            type = "SimpleIMAPSSLRetriever";
            server = "imap.forced.example.org";
            username = "forced-user";
            password_command = "('helper', '--account', 'forced')";
          };
          destination = {
            type = "MDA_external";
            path = "/bin/true";
          };
        };
      };
    };
    netrc-account = {
      address = "netrc@example.org";
      realName = "Netrc Account";
      userName = "netrc-user";
      imap.host = "imap.netrc.example.org";
      getmail = {
        enable = true;
        mailboxes = [ "INBOX" ];
        settings.options.use_netrc = true;
      };
    };
    hm-account = {
      imap = lib.mkForce null;
      getmail = {
        enable = true;
        delete = lib.mkDefault true;
        settings = {
          retriever = {
            type = "SimpleIMAPSSLRetriever";
            server = "imap.native.example.org";
            port = 993;
            username = "native-user";
            mailboxes = "('INBOX', 'Archive')";
            password_command = "('helper', '--account', 'secondary')";
          };
          destination = {
            type = "MDA_external";
            path = "/bin/true";
            arguments = "('--mail',)";
          };
        };
      };
    };
  };

  services.getmail.enable = true;

  nmt.script = ''
    assertFileRegex home-files/.config/systemd/user/getmail.service ' --rcfile getmailhm-account'
    assertFileRegex home-files/.config/systemd/user/getmail.service ' --rcfile getmailrc'
    assertPathNotExists home-files/.getmail/getmaildisabled-account
    assertFileContent home-files/.getmail/getmailrc ${./settings-primary.conf}
    assertFileContent home-files/.getmail/getmailhm-account ${./settings-native.conf}
    assertFileContent home-files/.getmail/getmailforced-account ${./settings-forced.conf}
    assertFileContent home-files/.getmail/getmailnetrc-account ${./settings-netrc.conf}
  '';
}
