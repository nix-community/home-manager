{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ ../accounts/email-test-accounts.nix ];

  config = {
    home.username = "hm-user";
    home.homeDirectory = "/home/hm-user";

    accounts.email.accounts = {
      "hm@example.com".getmail = {
        enable = true;
        mailboxes = ["INBOX" "Sent" "Work"];
        destinationCommand = "/bin/maildrop";
        delete = false;
      };
    };

    nmt.script = ''
      assertFileExists home-files/.getmail/getmailhm@example.com
      assertFileContent home-files/.getmail/getmailhm@example.com ${./getmail-expected.conf}
    '';
  };
}
